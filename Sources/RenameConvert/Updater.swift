// Проверка и установка обновлений из GitHub Releases.

import AppKit
import CryptoKit
import Observation

@MainActor
@Observable
final class Updater {
    struct Release: Equatable {
        let version: String
        let notes: String
        let pageURL: URL
        let zipURL: URL
        /// SHA-256 архива из GitHub API (`digest: "sha256:…"`), если есть.
        let sha256: String?
    }

    enum State: Equatable {
        case idle
        case checking
        case upToDate
        case available(Release)
        case installing
        case failed(String)
    }

    private(set) var state: State = .idle
    private(set) var lastCheck: Date?
    var automatic: Bool { didSet { UserDefaults.standard.set(automatic, forKey: "autoCheckUpdates") } }

    /// Вызывается, когда при автоматической проверке нашлась новая версия.
    @ObservationIgnored var onUpdateFound: ((Release) -> Void)?

    let repository: String = Bundle.main.object(forInfoDictionaryKey: "RCUpdateRepository") as? String ?? "Kohinor46/RenameConvert"
    let currentVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"

    var releasesPage: URL { URL(string: "https://github.com/\(repository)/releases")! }

    init() {
        UserDefaults.standard.register(defaults: ["autoCheckUpdates": true])
        automatic = UserDefaults.standard.bool(forKey: "autoCheckUpdates")
        lastCheck = UserDefaults.standard.object(forKey: "lastUpdateCheck") as? Date
    }

    /// Автоматическая проверка не чаще раза в сутки.
    func checkAutomaticallyIfNeeded() {
        guard automatic, Bundle.main.bundleIdentifier != nil else { return }
        if let lastCheck, Date().timeIntervalSince(lastCheck) < 24 * 3600 { return }
        Task { await check(userInitiated: false) }
    }

    func check(userInitiated: Bool) async {
        if case .installing = state { return }
        state = .checking
        do {
            var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(repository)/releases/latest")!)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("RenameConvert/\(currentVersion)", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            if (response as? HTTPURLResponse)?.statusCode == 404 { throw UpdateError.noReleases }
            let release = try Self.parse(data)
            lastCheck = Date()
            UserDefaults.standard.set(lastCheck, forKey: "lastUpdateCheck")
            if Self.isNewer(release.version, than: currentVersion) {
                state = .available(release)
                Log.info("Доступно обновление \(release.version)")
                if !userInitiated { onUpdateFound?(release) }
            } else {
                state = .upToDate
            }
        } catch {
            Log.error("Проверка обновлений: \(error)")
            state = userInitiated ? .failed(error.localizedDescription) : .idle
        }
    }

    /// Скачивает архив, проверяет его и заменяет приложение, затем перезапускает.
    func install(_ release: Release) async {
        state = .installing
        do {
            let fm = FileManager.default
            let appURL = Bundle.main.bundleURL
            let work = try fm.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: appURL, create: true)
            defer { try? fm.removeItem(at: work) }

            let (downloaded, _) = try await URLSession.shared.download(from: release.zipURL)
            let zip = work.appendingPathComponent("update.zip")
            try fm.moveItem(at: downloaded, to: zip)

            if let expected = release.sha256 {
                let actual = SHA256.hash(data: try Data(contentsOf: zip)).map { String(format: "%02x", $0) }.joined()
                guard actual == expected.lowercased() else { throw UpdateError.checksumMismatch }
            }

            let unpacked = work.appendingPathComponent("unpacked")
            try await Shell.run("/usr/bin/ditto", ["-x", "-k", zip.path, unpacked.path])
            guard let newApp = try fm.contentsOfDirectory(at: unpacked, includingPropertiesForKeys: nil)
                .first(where: { $0.pathExtension == "app" }),
                  let info = NSDictionary(contentsOf: newApp.appendingPathComponent("Contents/Info.plist")),
                  info["CFBundleIdentifier"] as? String == Bundle.main.bundleIdentifier else {
                throw UpdateError.badArchive
            }
            try await Shell.run("/usr/bin/codesign", ["--verify", "--deep", newApp.path])

            _ = try fm.replaceItemAt(appURL, withItemAt: newApp)
            Log.info("Установлено обновление \(release.version), перезапуск")

            AppRelauncher.relaunch()
        } catch {
            Log.error("Установка обновления: \(error)")
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: Разбор ответа

    private static func parse(_ data: Data) throws -> Release {
        struct Asset: Decodable {
            let name: String
            let browser_download_url: URL
            let digest: String?
        }
        struct Response: Decodable {
            let tag_name: String
            let body: String?
            let html_url: URL
            let assets: [Asset]
        }
        let response = try JSONDecoder().decode(Response.self, from: data)
        guard let zip = response.assets.first(where: { $0.name.hasSuffix(".zip") }) else { throw UpdateError.badArchive }
        let sha = zip.digest.flatMap { $0.hasPrefix("sha256:") ? String($0.dropFirst(7)) : nil }
        let version = response.tag_name.hasPrefix("v") ? String(response.tag_name.dropFirst()) : response.tag_name
        return Release(version: version, notes: response.body ?? "", pageURL: response.html_url,
                       zipURL: zip.browser_download_url, sha256: sha)
    }

    static func isNewer(_ a: String, than b: String) -> Bool {
        let pa = a.split(separator: ".").map { Int($0) ?? 0 }, pb = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(pa.count, pb.count) {
            let x = i < pa.count ? pa[i] : 0, y = i < pb.count ? pb[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}

enum UpdateError: LocalizedError {
    case noReleases, badArchive, checksumMismatch

    var errorDescription: String? {
        switch self {
        case .noReleases: return String(localized: "Релизов пока нет.")
        case .badArchive: return String(localized: "Архив обновления повреждён или не подходит.")
        case .checksumMismatch: return String(localized: "Контрольная сумма архива не совпала — обновление не установлено.")
        }
    }
}
