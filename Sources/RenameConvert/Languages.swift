// Языки интерфейса и перезапуск приложения.

import AppKit

enum AppLanguage {
    /// Коды .lproj и самоназвания языков (не переводятся).
    static let all: [(code: String, name: String)] = [
        ("en", "English"), ("ru", "Русский"), ("de", "Deutsch"), ("fr", "Français"), ("es", "Español"),
        ("it", "Italiano"), ("pt-BR", "Português (Brasil)"), ("nl", "Nederlands"), ("pl", "Polski"),
        ("uk", "Українська"), ("cs", "Čeština"), ("sv", "Svenska"), ("tr", "Türkçe"), ("ar", "العربية"),
        ("he", "עברית"), ("hi", "हिन्दी"), ("id", "Bahasa Indonesia"), ("vi", "Tiếng Việt"), ("th", "ไทย"),
        ("ja", "日本語"), ("ko", "한국어"), ("zh-Hans", "简体中文"), ("zh-Hant", "繁體中文"),
    ]

    /// Язык, выбранный в приложении («» — как в системе). Хранится в AppleLanguages домена приложения.
    static var selected: String {
        guard let id = Bundle.main.bundleIdentifier,
              let list = UserDefaults.standard.persistentDomain(forName: id)?["AppleLanguages"] as? [String],
              let first = list.first else { return "" }
        return all.first { $0.code == first }?.code ?? ""
    }

    static func select(_ code: String) {
        if code.isEmpty {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        }
    }
}

enum AppRelauncher {
    /// Запускает приложение заново после выхода текущего экземпляра.
    static func relaunch() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "sleep 1; /usr/bin/open \"$0\"", Bundle.main.bundleURL.path]
        try? process.run()
        NSApp.terminate(nil)
    }
}
