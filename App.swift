import SwiftUI

@main
struct NFCApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ReadView()
                    .tabItem { Label("Чтение", systemImage: "wave.3.right.circle") }
                WriteView()
                    .tabItem { Label("Запись", systemImage: "square.and.pencil") }
                TasksView()
                    .tabItem { Label("Задачи", systemImage: "bolt.circle") }
            }
        }
    }
}
