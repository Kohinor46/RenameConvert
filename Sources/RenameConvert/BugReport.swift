// Отчёт об ошибке: письмо в «Почте» с описанием, сведениями о системе и журналом во вложении.

import AppKit
import SwiftUI

enum BugReport {
    static let recipient = "punk19922009@gmail.com"

    /// Собирает файл отчёта: система, версия, настройки, журнал.
    @MainActor
    static func makeReportFile(description: String, includeLog: Bool, model: AppModel) throws -> URL {
        let info = ProcessInfo.processInfo
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        var arch = utsname()
        uname(&arch)
        let machine = withUnsafeBytes(of: &arch.machine) { String(decoding: $0.prefix(while: { $0 != 0 }), as: UTF8.self) }

        var text = """
        RenameConvert \(version)
        macOS \(info.operatingSystemVersionString), \(machine)
        Language: \(Locale.preferredLanguages.first ?? "?")
        ffmpeg: \(FFmpeg.isAvailable ? "yes" : "no")
        Date: \(ISO8601DateFormatter().string(from: Date()))

        == Description ==
        \(description)

        == Settings ==
        paused=\(model.paused) keepOriginal=\(model.keepOriginal) defaultAction=\(model.defaultAction.rawValue)
        folders=\(model.folders.count) excluded=\(model.excludedFolders.count)
        rules=\(model.rules.map { "\($0.from.title)→\($0.to.title):\($0.action.rawValue)" }.joined(separator: ", "))
        params=\(String(describing: model.params))
        lastError=\(model.lastError ?? "-")
        """
        if includeLog {
            text += "\n\n== Log (\(Log.url.path)) ==\n" + Log.tail(lines: 500)
        }

        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("RenameConvert-report-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("RenameConvert-report.txt")
        try Data(text.utf8).write(to: file)
        return file
    }

    /// Открывает готовое письмо. Возвращает false, если почтовая программа не настроена.
    @MainActor
    static func compose(description: String, includeLog: Bool, model: AppModel) -> Bool {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let subject = "RenameConvert \(version): " + String(localized: "отчёт об ошибке")
        guard let file = try? makeReportFile(description: description, includeLog: includeLog, model: model) else { return false }
        Log.info("Подготовлен отчёт об ошибке: \(file.path)")

        if let service = NSSharingService(named: .composeEmail), service.canPerform(withItems: [description, file]) {
            service.recipients = [recipient]
            service.subject = subject
            service.perform(withItems: [description, file])
            return true
        }
        // Почта не настроена: открываем mailto без вложения и показываем файл отчёта.
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: description + "\n\n" + String(localized: "(Приложите файл RenameConvert-report.txt из открывшейся папки.)")),
        ]
        if let url = components.url { NSWorkspace.shared.open(url) }
        NSWorkspace.shared.activateFileViewerSelecting([file])
        return false
    }
}

/// Окно отчёта — обычное NSWindow, чтобы открывать его и из уведомлений.
@MainActor
final class ReportWindowController {
    private weak var model: AppModel?
    private var window: NSWindow?

    init(model: AppModel) {
        self.model = model
    }

    func show() {
        guard let model else { return }
        window?.close()
        let host = NSHostingController(rootView: BugReportView(model: model) { [weak self] in self?.window?.close() })
        host.sizingOptions = [.preferredContentSize]
        let window = NSWindow(contentViewController: host)
        window.title = String(localized: "Сообщить об ошибке")
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }
}

struct BugReportView: View {
    let model: AppModel
    let close: () -> Void
    @State private var details = ""
    @State private var includeLog = true
    @State private var fallbackUsed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Сообщить об ошибке").font(.title2.bold())
            Text("Опишите, что произошло и что вы ожидали. Будет создано письмо разработчику — проверьте его и нажмите «Отправить».")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            TextEditor(text: $details)
                .font(.body)
                .frame(minHeight: 140)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))

            Toggle("Приложить журнал работы и сведения о системе", isOn: $includeLog)
            Text("В журнале есть имена и пути файлов, которые вы конвертировали. Содержимое файлов не отправляется.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if fallbackUsed {
                Label("Почта не настроена: открыто письмо без вложения и папка с файлом отчёта — приложите его вручную.",
                      systemImage: "info.circle")
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Button("Показать журнал") { NSWorkspace.shared.activateFileViewerSelecting([Log.url]) }
                Spacer()
                Button("Отмена", action: close)
                    .keyboardShortcut(.cancelAction)
                Button("Создать письмо") {
                    if BugReport.compose(description: details, includeLog: includeLog, model: model) {
                        close()
                    } else {
                        fallbackUsed = true
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 480)
        .onAppear {
            if let draft = model.reportDraft {
                details = draft
                model.reportDraft = nil
            }
        }
    }
}
