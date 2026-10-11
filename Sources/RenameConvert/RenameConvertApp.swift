// RenameConvert — приложение в строке меню для macOS.
// Если у файла сменить расширение в Finder (photo.heic → photo.jpg, clip.mov → clip.mp4),
// его содержимое перекодируется в новый формат.

import SwiftUI

@main
struct RenameConvertApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: model)
        } label: {
            MenuBarLabel(model: model)
        }

        Window("RenameConvert", id: SettingsView.windowID) {
            SettingsView(model: model)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(model.isFirstLaunch ? .presented : .suppressed)
    }
}

/// Значок в строке меню; во время конвертации — с процентами.
struct MenuBarLabel: View {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        icon
            .onAppear {
                // Даём модели способ открыть настройки (например, по клику на уведомление).
                model.openSettings = { [openWindow] tab in
                    model.settingsTab = tab
                    openWindow(id: SettingsView.windowID)
                    NSApp.activate()
                }
            }
    }

    @ViewBuilder private var icon: some View {
        if !model.activeJobs.isEmpty {
            if let progress = model.overallProgress {
                Text("\(Image(systemName: "arrow.triangle.2.circlepath")) \(Int(progress * 100))%")
            } else {
                Image(systemName: "hourglass")
            }
        } else if !model.pendingAsks.isEmpty {
            Image(systemName: "questionmark.circle")
        } else {
            Image(systemName: model.paused ? "pause.circle" : "arrow.triangle.2.circlepath")
        }
    }
}

struct MenuContent: View {
    @Bindable var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(model.paused ? "На паузе" : "Следит за переименованиями")
        Toggle("Пауза", isOn: $model.paused)

        if !model.activeJobs.isEmpty {
            Divider()
            Section("Конвертируется") {
                ForEach(model.activeJobs) { job in
                    Button {
                        model.cancel(job)
                    } label: {
                        Text(job.progress.map { "\(job.title) — \(Int($0 * 100))%" } ?? job.title)
                        Text("Нажмите, чтобы отменить")
                    }
                }
            }
        }

        if !model.pendingAsks.isEmpty {
            Divider()
            Button("Ждут решения: \(model.pendingAsks.count)…") { model.showPendingAsks() }
        }

        if !model.history.isEmpty {
            Divider()
            Section("Недавние") {
                ForEach(model.history.prefix(5)) { entry in
                    Button("\(entry.oldName) → \(entry.newName)") { model.reveal(entry) }
                }
                Button("Вся история…") { showSettings(.history) }
            }
        }

        if case .available(let release) = model.updater.state {
            Divider()
            Button("Доступна версия \(release.version)…") { showSettings(.about) }
        }

        Divider()
        Button("Правила…") { showSettings(.rules) }
        Button("Настройки…") { showSettings(.general) }
            .keyboardShortcut(",")
        Button("Проверить обновления…") {
            showSettings(.about)
            Task { await model.updater.check(userInitiated: true) }
        }
        Button("Сообщить об ошибке…") { model.openReport() }
        Button("Выйти из RenameConvert") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    private func showSettings(_ tab: SettingsTab) {
        model.settingsTab = tab
        openWindow(id: SettingsView.windowID)
        NSApp.activate()
    }
}
