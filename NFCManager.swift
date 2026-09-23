import Foundation
import CoreNFC
import SwiftUI

enum NFCError: LocalizedError {
    case notAvailable
    case sessionFailed(String)
    var errorDescription: String? {
        switch self {
        case .notAvailable: return "NFC недоступно на этом устройстве"
        case .sessionFailed(let m): return m
        }
    }
}

struct TagRecord: Identifiable {
    let id = UUID()
    let type: String
    let text: String
    let data: [UInt8]
}

struct TagInfo {
    var serial: String = "—"
    var technologies: [String] = []
    var size: Int = 0
    var writable: Bool = false
    var records: [TagRecord] = []
}

/// Вся логика работы с Core NFC
final class NFCManager: NSObject, ObservableObject, NFCTagReaderSessionDelegate, NFCNDEFReaderSessionDelegate {
    @Published var tag: TagInfo?
    @Published var statusMessage: String = ""
    @Published var statusIsError: Bool = false

    private var readerSession: NFCNDEFReaderSession?
    private var tagRef: (any NFCNDEFTag)?

    // MARK: - Чтение

    func startReading() {
        guard NFCNDEFReaderSession.readingAvailable else {
            setStatus("NFC-чтение недоступно (iPhone 7+ и только NDEF-метки)", error: true)
            return
        }
        tagRef = nil
        readerSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        readerSession?.alertMessage = "Поднесите iPhone к NFC-метке"
        readerSession?.begin()
    }

    // MARK: - Запись

    func startWriting(records: [NFCNDEFPayload]) {
        guard NFCNDEFReaderSession.readingAvailable else {
            setStatus("NFC-запись недоступна на этом устройстве", error: true)
            return
        }
        tagRef = nil
        readerSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        readerSession?.alertMessage = "Поднесите iPhone к NFC-метке для записи"
        readerSession?.begin()
        pendingWrite = records
    }

    private var pendingWrite: [NFCNDEFPayload]?

    func startErasing() {
        guard NFCNDEFReaderSession.readingAvailable else {
            setStatus("NFC недоступно", error: true)
            return
        }
        tagRef = nil
        readerSession = NFCNDEFReaderSession(
            delegate: self, queue: nil, invalidateAfterFirstRead: false)
        readerSession?.alertMessage = "Поднесите iPhone к метке для очистки"
        readerSession?.begin()
        pendingErase = true
    }

    private var pendingErase = false

    // MARK: - NFCNDEFReaderSessionDelegate

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let first = tags.first else { return }
        tagRef = first
        session.restartAlert()

        first.queryNDEFStatus { [weak self] status, capacity, error in
            guard let self else { return }
            if let error {
                session.invalidate(errorMessage: "Ошибка: \(error.localizedDescription)")
                return
            }

            if self.pendingErase {
                self.erase(on: first, session: session)
                return
            }

            if let payloads = self.pendingWrite {
                self.write(payloads, to: first, session: session, capacity: capacity)
                return
            }

            // чтение
            self.readPayloads(from: first, session: session, capacity: capacity, writable: status == .readWrite)
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            if let e = error as? NFCReaderError, e.code == .readerSessionInvalidationErrorFirstNDEFTagRead {
                // нормальное завершение после первой метки — не ошибка
            } else {
                self.setStatus(error.localizedDescription, error: true)
            }
        }
    }

    // MARK: - внутренние шаги

    private func readPayloads(from tag: any NFCNDEFTag, session: NFCNDEFReaderSession, capacity: Int, writable: Bool) {
        tag.readNDEF { [weak self] message, error in
            guard let self else { return }
            var info = TagInfo()
            info.size = capacity
            info.writable = writable
            info.technologies = ["NDEF", "ISO 14443 (NfcA)"]
            if let message {
                info.records = message.records.map { r in
                    TagRecord(type: typeName(of: r), text: textOf(r), data: r.payload.map { UInt8($0) })
                }
            }
            Task { @MainActor in
                self.tag = info
                self.setStatus("Метка прочитана", error: false)
            }
            session.invalidate()
        }
    }

    private func write(_ payloads: [NFCNDEFPayload], to tag: any NFCNDEFTag, session: NFCNDEFReaderSession, capacity: Int) {
        let message = NFCNDEFMessage(records: payloads)
        tag.writeNDEF(message) { [weak self] error in
            Task { @MainActor in
                if let error {
                    self.setStatus("Ошибка записи: \(error.localizedDescription)", error: true)
                } else {
                    self.setStatus("Запись успешна!", error: false)
                }
            }
            session.invalidate()
            self?.pendingWrite = nil
        }
    }

    private func erase(on tag: any NFCNDEFTag, session: NFCNDEFReaderSession) {
        let empty = NFCNDEFMessage(records: [])
        tag.writeNDEF(empty) { [weak self] error in
            Task { @MainActor in
                if let error {
                    self.setStatus("Ошибка очистки: \(error.localizedDescription)", error: true)
                } else {
                    self.tag?.records = []
                    self.setStatus("Метка очищена", error: false)
                }
            }
            session.invalidate()
            self?.pendingErase = false
        }
    }

    // MARK: - вспомогательные

    private func typeName(of p: NFCNDEFPayload) -> String {
        switch p.typeNameFormat {
        case .nfcWellKnown:
            if p.type == Data([0x55]) { return "URI" }
            if p.type == Data([0x54]) { return "Текст" }
            return "Well-Known"
        case .nfcAbsoluteURI: return "URI"
        case .nfcMedia: return "MIME"
        case .nfcExternal: return "External"
        default: return "Unknown"
        }
    }

    private func textOf(_ p: NFCNDEFPayload) -> String {
        // Быстрый парсер основных форматов
        let payload = p.payload
        if p.typeNameFormat == .nfcWellKnown && p.type == Data([0x54]) {
            guard payload.count > 1, let langLen = payload.first else { return "" }
            let start = 1 + Int(langLen)
            if start <= payload.count {
                let s = String(bytes: payload[start...], encoding: .utf8) ?? ""
                return s
            }
        }
        if p.typeNameFormat == .nfcWellKnown && p.type == Data([0x55]) {
            guard let prefixCode = payload.first else { return "" }
            let prefixes = ["", "http://www.", "https://www.", "http://", "https://",
                            "tel:", "mailto:", "ftp://", "ftp://ftp."]
            let rest = String(bytes: payload.dropFirst(), encoding: .utf8) ?? ""
            let prefix = Int(prefixCode) < prefixes.count ? prefixes[Int(prefixCode)] : ""
            return prefix + rest
        }
        if p.typeNameFormat == .absoluteURI, let s = String(bytes: payload, encoding: .utf8) {
            return s
        }
        return (try? p.wellKnownTypeTextPayload()?.0) ?? String(bytes: payload.prefix(64), encoding: .utf8) ?? ""
    }

    private func setStatus(_ s: String, error: Bool) {
        statusMessage = s
        statusIsError = error
    }
}

// MARK: - NFCTagReaderSessionDelegate (обязательные методы)
extension NFCManager {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {}
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {}
}
