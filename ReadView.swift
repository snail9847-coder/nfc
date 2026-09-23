import SwiftUI

struct ReadView: View {
    @EnvironmentObject var nfc: NFCManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    statusBanner

                    Button {
                        nfc.startReading()
                    } label: {
                        Label("Считать метку", systemImage: "wave.3.right")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    if let tag = nfc.tag {
                        Group {
                            infoCard(title: "Информация о метке") {
                                row("Серийный номер", "—")
                                row("Технологии", tag.technologies.joined(separator: ", "))
                                row("Размер", "\(tag.size) байт")
                                row("Записей NDEF", "\(tag.records.count)")
                            }

                            infoCard(title: "Данные (NDEF)") {
                                if tag.records.isEmpty {
                                    Text("NDEF-записей нет (пустая метка)")
                                        .foregroundColor(.secondary)
                                }
                                ForEach(tag.records) { r in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: iconFor(r.type))
                                            .foregroundColor(.accentColor)
                                            .frame(width: 24)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(r.type).font(.subheadline.weight(.semibold))
                                            Text(r.text)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(3)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    } else {
                        Text("Поднесите iPhone к NFC-метке или нажмите «Считать метку»")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Чтение")
        }
    }

    private var statusBanner: some View {
        Group {
            if !nfc.statusMessage.isEmpty {
                Text(nfc.statusMessage)
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(nfc.statusIsError ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                    .foregroundColor(nfc.statusIsError ? .red : .green)
                    .cornerRadius(10)
            }
        }
    }

    private func infoCard<D: View>(title: String, @ViewBuilder content: () -> D) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundColor(.secondary)
            Spacer()
            Text(v)
        }
        .font(.subheadline)
    }

    private func iconFor(_ type: String) -> String {
        switch type {
        case "URI": return "link"
        case "Текст": return "doc.text"
        case "SMS": return "message"
        default: return "doc"
        }
    }
}
