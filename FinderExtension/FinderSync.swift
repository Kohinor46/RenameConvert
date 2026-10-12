// Расширение Finder: пункт «Конвертировать в» в контекстном меню файлов.
// Расширение работает в песочнице и само ничего не конвертирует: выбор передаётся
// приложению ссылкой renameconvert://convert?to=jpg&path=… (см. AppModel.handleMenuURL).

import AppKit
import FinderSync

@objc(RCFinderSync)
final class FinderSync: FIFinderSync {
    override init() {
        super.init()
        // Меню нужно для файлов в любой папке.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems else { return nil }
        let groups = Self.targets(for: Self.selectedFiles())
        guard !groups.isEmpty else { return nil }

        let submenu = NSMenu()
        for (i, group) in groups.enumerated() {
            if i > 0 { submenu.addItem(.separator()) }
            for ext in group {
                // Finder копирует пункты меню, теряя representedObject, — формат берём из заголовка.
                submenu.addItem(NSMenuItem(title: ext.uppercased(), action: #selector(convert(_:)), keyEquivalent: ""))
            }
        }
        let item = NSMenuItem(title: String(localized: "Конвертировать в"), action: nil, keyEquivalent: "")
        item.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: nil)
        item.submenu = submenu
        let menu = NSMenu()
        menu.addItem(item)
        return menu
    }

    @objc func convert(_ sender: NSMenuItem) {
        let files = Self.selectedFiles()
        let to = sender.title.lowercased()
        let paths = files.filter { Formats.plan(from: Formats.fileExtension(of: $0.lastPathComponent), to: to) != nil }
        guard !paths.isEmpty else { return }

        // В пути могут быть & = + — кодируем всё, кроме безопасных символов.
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~/"))
        func encode(_ s: String) -> String { s.addingPercentEncoding(withAllowedCharacters: allowed) ?? s }
        var url = URLComponents()
        url.scheme = "renameconvert"
        url.host = "convert"
        url.percentEncodedQueryItems = [URLQueryItem(name: "to", value: encode(to))]
            + paths.map { URLQueryItem(name: "path", value: encode($0.path)) }
        if let url = url.url { NSWorkspace.shared.open(url) }
    }

    /// Выделенные файлы (папки и пакеты вроде .app не конвертируем).
    private static func selectedFiles() -> [URL] {
        (FIFinderSyncController.default().selectedItemURLs() ?? []).filter { $0.isFileURL && !$0.hasDirectoryPath }
    }

    /// Форматы, в которые можно сконвертировать все выделенные файлы сразу.
    static func targets(for files: [URL]) -> [[String]] {
        let exts = Set(files.map { Formats.fileExtension(of: $0.lastPathComponent) })
        guard let first = exts.first else { return [] }
        let rest = exts.dropFirst()
        return Formats.targets(from: first).compactMap { group in
            let common = group.filter { to in rest.allSatisfy { Formats.plan(from: $0, to: to) != nil } }
            return common.isEmpty ? nil : common
        }
    }
}

/// Formats.swift общий с приложением; ffmpeg лежит в самом приложении (Contents/Helpers/ffmpeg).
enum FFmpeg {
    static let isAvailable: Bool = {
        let contents = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
        return FileManager.default.fileExists(atPath: contents.appendingPathComponent("Helpers/ffmpeg").path)
    }()
}
