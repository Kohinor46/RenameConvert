// Пункт «Конвертировать в» в контекстном меню Finder (расширение FinderExtension/).
// Расширение в песочнице и передаёт выбор ссылкой renameconvert://convert?to=jpg&path=…

import AppKit
import FinderSync

enum FinderMenu {
    static let urlScheme = "renameconvert"
    static let extensionID = "local.renameconvert.FinderSync"

    /// Включено ли расширение в Системных настройках.
    static var isEnabled: Bool { FIFinderSyncController.isExtensionEnabled }

    /// Открывает список расширений Finder в Системных настройках.
    static func showSettings() {
        FIFinderSyncController.showExtensionManagementInterface()
    }

    /// Первый запуск версии с расширением — включает его (если пользователь потом выключит, не трогаем).
    /// После обновления Finder теряет процесс старого расширения и сам не перезапускает — перезапускаем.
    static func setUp(defaults: UserDefaults = .standard) {
        guard let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else { return }
        let enabledKey = "finderExtensionEnabledOnce", buildKey = "finderExtensionBuild"
        let commands: [[String]]
        if !defaults.bool(forKey: enabledKey) {
            commands = [["-e", "use"]]
        } else if defaults.string(forKey: buildKey) != build, isEnabled {
            commands = [["-e", "ignore"], ["-e", "use"]]
        } else {
            commands = []
        }
        defaults.set(true, forKey: enabledKey)
        defaults.set(build, forKey: buildKey)
        guard !commands.isEmpty else { return }
        DispatchQueue.global(qos: .utility).async {
            for args in commands {
                let pluginkit = Process()
                pluginkit.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
                pluginkit.arguments = args + ["-i", extensionID]
                do {
                    try pluginkit.run()
                    pluginkit.waitUntilExit()
                } catch {
                    Log.error("pluginkit \(args.joined(separator: " ")): \(error)")
                }
            }
        }
    }

    /// Разбирает ссылку от расширения: в какой формат и какие файлы.
    static func parse(_ url: URL) -> (to: String, paths: [String])? {
        guard url.scheme == urlScheme, url.host == "convert",
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let to = items.first(where: { $0.name == "to" })?.value?.lowercased(), !to.isEmpty else { return nil }
        let paths = items.filter { $0.name == "path" }.compactMap(\.value).filter { $0.hasPrefix("/") }
        return paths.isEmpty ? nil : (to, paths)
    }

    /// Свободное имя для результата: «photo.jpg», занято — «photo 2.jpg», «photo 3.jpg»…
    static func destination(for path: String, to ext: String, fileManager fm: FileManager = .default) -> String? {
        let name = (path as NSString).lastPathComponent, dir = (path as NSString).deletingLastPathComponent
        let from = Formats.fileExtension(of: name)
        guard !from.isEmpty else { return nil }
        let base = String(name.dropLast(from.count + 1))
        var candidate = (dir as NSString).appendingPathComponent("\(base).\(ext)")
        var n = 2
        while fm.fileExists(atPath: candidate) {
            candidate = (dir as NSString).appendingPathComponent("\(base) \(n).\(ext)")
            n += 1
        }
        return candidate
    }
}

/// Принимает ссылки renameconvert:// и пропускает только те, что прислало наше расширение:
/// иначе любая веб-страница могла бы конвертировать файлы пользователя.
final class FinderMenuURLReceiver: NSObject {
    private let handler: (URL) -> Void

    init(handler: @escaping (URL) -> Void) {
        self.handler = handler
        super.init()
        // SwiftUI ставит свой обработчик при запуске и затирает наш, поэтому регистрируемся после.
        NotificationCenter.default.addObserver(self, selector: #selector(register),
                                               name: NSApplication.didFinishLaunchingNotification, object: nil)
    }

    @objc private func register() {
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handle(_:reply:)),
                                                     forEventClass: AEEventClass(kInternetEventClass),
                                                     andEventID: AEEventID(kAEGetURL))
    }

    @objc private func handle(_ event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        guard let string = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: string) else { return }
        let plugIns = Bundle.main.bundleURL.appendingPathComponent("Contents/PlugIns").resolvingSymlinksInPath().path + "/"
        let sender = senderPath(event)
        guard let sender, sender.hasPrefix(plugIns) else {
            Log.error("Ссылка \(url.scheme ?? "") не от расширения Finder (отправитель: \(sender ?? "неизвестен")), пропущена")
            return
        }
        handler(url)
    }

    /// Путь к коду отправителя — по audit token, а не по PID (PID мог уже достаться другому процессу).
    private func senderPath(_ event: NSAppleEventDescriptor) -> String? {
        guard let token = event.attributeDescriptor(forKeyword: AEKeyword(keySenderAuditTokenAttr))?.data else { return nil }
        var code: SecCode?
        var staticCode: SecStaticCode?
        var url: CFURL?
        guard SecCodeCopyGuestWithAttributes(nil, [kSecGuestAttributeAudit: token] as CFDictionary, [], &code) == errSecSuccess,
              let code, SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess,
              let staticCode, SecCodeCopyPath(staticCode, [], &url) == errSecSuccess, let url else { return nil }
        return (url as URL).resolvingSymlinksInPath().path
    }
}
