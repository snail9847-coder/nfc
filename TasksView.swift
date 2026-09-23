import SwiftUI

struct TaskItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    var on: Bool
}

struct TasksView: View {
    @State private var tasks: [TaskItem] = [
        .init(icon: "wifi", title: "Включить Wi-Fi", subtitle: "Точка HOME-NET", on: true),
        .init(icon: "antenna.radiowaves.left.and.right", title: "Включить Bluetooth", subtitle: "Наушники", on: false),
        .init(icon: "speaker.wave.3", title: "Громкость 80%", subtitle: "Медиа", on: true),
        .init(icon: "sun.max", title: "Яркость: авто", subtitle: "Адаптивная", on: false),
        .init(icon: "link", title: "Открыть сайт", subtitle: "nfc-tools.app", on: false),
        .init(icon: "alarm", title: "Будильник 7:00", subtitle: "Рабочие дни", on: false),
    ]

    @State private var resultMessage = ""

    var body: some View {
        NavigationView {
            List {
                Section("NFC Задачи — действия при поднесении метки") {
                    ForEach($tasks) { $t in
                        HStack {
                            Image(systemName: t.icon)
                                .foregroundColor(.accentColor)
                                .frame(width: 30)
                            VStack(alignment: .leading) {
                                Text(t.title)
                                Text(t.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Toggle("", isOn: $t.on).labelsHidden()
                        }
                    }
                }
                Section {
                    Button {
                        runTasks()
                    } label: {
                        Label("Выполнить задачи", systemImage: "bolt.fill")
                            .frame(maxWidth: .infinity)
                    }
                    if !resultMessage.isEmpty {
                        Text(resultMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Задачи")
        }
    }

    private func runTasks() {
        let active = tasks.filter(\.on)
        if active.isEmpty {
            resultMessage = "Не выбрано ни одной задачи."
            return
        }
        if let site = active.first(where: { $0.subtitle == "nfc-tools.app" }) {
            _ = site
            if let url = URL(string: "https://nfc-tools.app") {
                UIApplication.shared.open(url)
            }
        }
        resultMessage = "Выполнено задач: \(active.count)"
    }
}
