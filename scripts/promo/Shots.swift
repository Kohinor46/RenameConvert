// Снимает окна приложения (правила, история, окно-вопрос и др.) для промо-ролика и проверки переводов.
// Собирается вместе с исходниками приложения и запускается из .app-обёртки с нужным языком:
//   Shots.app/Contents/MacOS/shots <рабочая папка> <папка для png> -AppleLanguages "(en)"

import SwiftUI

@MainActor func snapshot(_ view: NSView, _ path: String) {
    let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
    view.cacheDisplay(in: view.bounds, to: rep)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

@main
struct Shots {
    static func main() {
        let dir = CommandLine.arguments[1], out = CommandLine.arguments[2]
        try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
        let d = UserDefaults.standard
        d.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        d.set(true, forKey: "launchedBefore")
        d.set(false, forKey: "autoCheckUpdates")
        d.set([dir], forKey: "folders")
        // История с настоящими файлами — чтобы были миниатюры.
        let entries = [
            HistoryEntry(date: Date().addingTimeInterval(-90), directory: dir, oldName: "vacation.HEIC", newName: "vacation.jpg", trashedOriginal: "/tmp"),
            HistoryEntry(date: Date().addingTimeInterval(-600), directory: dir, oldName: "clip.mov", newName: "clip.gif", trashedOriginal: "/tmp"),
            HistoryEntry(date: Date().addingTimeInterval(-3600), directory: dir, oldName: "interview.mkv", newName: "interview.mp3", trashedOriginal: "/tmp"),
            HistoryEntry(date: Date().addingTimeInterval(-7200), directory: dir, oldName: "report.docx", newName: "report.pdf", trashedOriginal: "/tmp"),
            HistoryEntry(date: Date().addingTimeInterval(-86400), directory: dir, oldName: "logo.png", newName: "logo.webp", trashedOriginal: nil, restored: true),
        ]
        d.set(try! JSONEncoder().encode(entries), forKey: "history")

        NSApplication.shared.setActivationPolicy(.accessory)
        NSApplication.shared.appearance = NSAppearance(named: .aqua)
        MainActor.assumeIsolated {
            let model = AppModel()
            model.rules = Rule.defaults + [
                Rule(from: .ext("heic"), to: .ext("jpg"), action: .convert, keepOriginal: .keep),
                Rule(from: .category(.archive), to: .any, action: .skip),
                Rule(from: .any, to: .ext("pdf"), action: .ask),
            ]
            RunLoop.main.run(until: Date().addingTimeInterval(1))

            // Окно-вопрос — настоящим путём через переименование.
            rename(dir + "/holiday.mov", dir + "/holiday.mp4")
            RunLoop.main.run(until: Date().addingTimeInterval(2.5))
            if let panel = NSApp.windows.first(where: { $0 is NSPanel && $0.isVisible }) {
                snapshot(panel.contentView!, out + "/ask.png")
                panel.orderOut(nil)
            } else {
                print("no ask panel")
            }

            for (tab, name) in [(SettingsTab.general, "general"), (.history, "history"), (.params, "params"),
                                (.rules, "rules"), (.formats, "formats"), (.about, "about"), (.donate, "donate")] {
                model.settingsTab = tab
                let host = NSHostingView(rootView: SettingsView(model: model))
                host.frame = NSRect(x: 0, y: 0, width: 880, height: 580)
                let win = NSWindow(contentRect: host.frame, styleMask: [.titled], backing: .buffered, defer: false)
                win.contentView = host
                win.orderFrontRegardless()
                RunLoop.main.run(until: Date().addingTimeInterval(2.0))
                snapshot(host, out + "/\(name).png")
                win.close()
            }
        }
        d.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }
}
