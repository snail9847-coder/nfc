import SwiftUI
import CoreNFC

enum RecordType: String, CaseIterable, Identifiable {
    case text = "Текст"
    case url = "Ссылка"
    case sms = "SMS"
    case geo = "Гео"
    var id: String { rawValue }
}

struct PendingRecord: Identifiable {
    let id = UUID()
    let type: RecordType
    let title: String
    let payload: NFCNDEFPayload
}

struct WriteView: View {
    @EnvironmentObject var nfc: NFCManager
    @State private var selected: RecordType = .text
    @State private var text = "Привет, NFC!"
    @State private var url = "https://example.com"
    @State private var tel = "+79001234567"
    @State private var sms = "Привет!"
    @State private var lat = "55.7558"
    @State private var lon = "37.6173"
    @State private var pending: [PendingRecord] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if !nfc.statusMessage.isEmpty {
                        Text(nfc.statusMessage)
                            .font(.subheadline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(nfc.statusIsError ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                            .cornerRadius(10)
                    }

                    typePicker

                    Group {
                        switch selected {
                        case .text:
                            VStack(alignment: .leading) {
                                Text("Текст").font(.caption).foregroundColor(.secondary)
                                TextEditor(text: $text).frame(minHeight: 80)
                            }
                        case .url:
                            field("URL", $url)
                        case .sms:
                            field("Номер", $tel)
                            field("Сообщение", $sms)
                        case .geo:
                            field("Широта", $lat)
                            field("Долгота", $lon)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    Button {
                        addRecord()
                    } label: {
                        Label("Добавить запись", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                    }

                    if !pending.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Записи (\(pending.count))").font(.headline)
                            ForEach(pending) { r in
                                HStack {
                                    Text(r.title)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Button {
                                        pending.removeAll { $0.id == r.id }
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                                Divider()
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                    }

                    Button {
                        nfc.startWriting(records: pending.map(\.payload))
                    } label: {
                        Label("Записать на метку", systemImage: "square.and.arrow.down")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(pending.isEmpty ? Color(.systemGray4) : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(pending.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Запись")
        }
    }

    private var typePicker: some View {
        Picker("Тип", selection: $selected) {
            ForEach(RecordType.allCases) { t in
                Text(t.rawValue).tag(t)
            }
        }
        .pickerStyle(.segmented)
    }

    private func field(_ title: String, _ binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            TextField("", text: binding)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func addRecord() {
        let payload: NFCNDEFPayload
        switch selected {
        case .text:
            payload = (try? NFCNDEFPayload.wellKnownTypeTextPayload(string: text, locale: Locale(identifier: "ru"))) ?? .init()
        case .url:
            payload = (try? NFCNDEFPayload.wellKnownTypeURIPayload(string: url)) ?? .init()
        case .sms:
            let uri = "sms:\(tel)?body=\(sms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            payload = (try? NFCNDEFPayload.wellKnownTypeURIPayload(string: uri)) ?? .init()
        case .geo:
            let uri = "geo:\(lat),\(lon)"
            payload = (try? NFCNDEFPayload.wellKnownTypeURIPayload(string: uri)) ?? .init()
        }
        pending.append(PendingRecord(type: selected, title: selected.rawValue, payload: payload))
    }
}
