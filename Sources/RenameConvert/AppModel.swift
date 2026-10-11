// Состояние приложения: настройки, правила, очередь, история.

import AppKit
import AVFoundation
import Observation
import ServiceManagement
import UserNotifications

struct HistoryEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var directory: String
    var oldName: String
    var newName: String
    var trashedOriginal: String?
    var restored = false

    var convertedPath: String { (directory as NSString).appendingPathComponent(newName) }
}

/// Конвертация, которая идёт прямо сейчас.
struct ActiveJob: Identifiable {
    let id: UUID
    let title: String
    var progress: Double?
    var task: Task<Void, Never>?
}

/// Конвертация, ждущая решения пользователя.
struct PendingAsk: Identifiable {
    var job: ConversionJob
    var id: UUID { job.id }
}

@MainActor
@Observable
final class AppModel {
    var paused: Bool { didSet { defaults.set(paused, forKey: Keys.paused) } }
    var keepOriginal: Bool { didSet { defaults.set(keepOriginal, forKey: Keys.keepOriginal) } }
    var notify: Bool { didSet { defaults.set(notify, forKey: Keys.notify) } }
    var defaultAction: RuleAction { didSet { defaults.set(defaultAction.rawValue, forKey: Keys.defaultAction) } }
    var params: ConversionParams { didSet { save(params, forKey: Keys.params) } }
    var rules: [Rule] { didSet { save(rules, forKey: Keys.rules) } }
    var folders: [String] {
        didSet {
            defaults.set(folders, forKey: Keys.folders)
            watcher.start(paths: folders)
        }
    }
    var excludedFolders: [String] { didSet { defaults.set(excludedFolders, forKey: Keys.excluded) } }

    private(set) var history: [HistoryEntry] = []
    private(set) var activeJobs: [ActiveJob] = []
    private(set) var pendingAsks: [PendingAsk] = []
    private(set) var launchAtLogin = SMAppService.mainApp.status == .enabled
    private(set) var lastError: String?
    /// Какая вкладка открыта в окне настроек.
    var settingsTab: SettingsTab = .general
    /// Текст, которым заполнится окно отчёта об ошибке.
    var reportDraft: String?
    /// Язык интерфейса, выбранный в приложении («» — как в системе).
    private(set) var appLanguage = AppLanguage.selected
    /// Язык выбран, но приложение ещё не перезапущено.
    private(set) var languageChanged = false

    let updater = Updater()
    /// Открывает окно настроек; задаётся из SwiftUI (там есть openWindow).
    @ObservationIgnored var openSettings: ((SettingsTab) -> Void)?
    @ObservationIgnored private lazy var reportWindow = ReportWindowController(model: self)
    @ObservationIgnored private var updateTimer: Timer?

    let isFirstLaunch: Bool

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private let watcher = RenameWatcher()
    /// Пути, события по которым игнорируем (наши собственные перемещения).
    @ObservationIgnored private var suppressed: [String: Date] = [:]
    @ObservationIgnored private let notifications = NotificationManager()
    @ObservationIgnored private lazy var askPanel = AskPanelController(model: self)

    private enum Keys {
        static let paused = "paused", keepOriginal = "keepOriginal", notify = "notify"
        static let defaultAction = "defaultAction", params = "params", rules = "rules"
        static let folders = "folders", excluded = "excludedFolders", history = "history", launched = "launchedBefore"
        static let conversions = "conversionCount", donatePrompted = "donatePromptShown"
    }

    init() {
        defaults.register(defaults: [
            Keys.paused: false, Keys.keepOriginal: true, Keys.notify: true,
            Keys.defaultAction: RuleAction.convert.rawValue,
            Keys.folders: [NSHomeDirectory()], Keys.excluded: [String](),
        ])
        paused = defaults.bool(forKey: Keys.paused)
        keepOriginal = defaults.bool(forKey: Keys.keepOriginal)
        notify = defaults.bool(forKey: Keys.notify)
        defaultAction = RuleAction(rawValue: defaults.string(forKey: Keys.defaultAction) ?? "") ?? .convert
        folders = defaults.stringArray(forKey: Keys.folders) ?? [NSHomeDirectory()]
        excludedFolders = defaults.stringArray(forKey: Keys.excluded) ?? []

        var params = Self.load(ConversionParams.self, from: defaults, key: Keys.params) ?? ConversionParams()
        if defaults.object(forKey: Keys.params) == nil, defaults.object(forKey: "quality") != nil {
            params.imageQuality = defaults.double(forKey: "quality")   // настройка из версии 1.0
        }
        self.params = params
        rules = Self.load([Rule].self, from: defaults, key: Keys.rules) ?? Rule.defaults
        history = Self.load([HistoryEntry].self, from: defaults, key: Keys.history) ?? []

        isFirstLaunch = !defaults.bool(forKey: Keys.launched)
        if isFirstLaunch {
            defaults.set(true, forKey: Keys.launched)
            setLaunchAtLogin(true)
        }

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
        Log.info("Запуск RenameConvert \(version), macOS \(ProcessInfo.processInfo.operatingSystemVersionString), ffmpeg: \(FFmpeg.isAvailable)")

        notifications.setUp()
        notifications.onReport = { [weak self] text in self?.openReport(draft: text) }
        notifications.onUpdate = { [weak self] in self?.showUpdate() }
        notifications.onDonate = { [weak self] in self?.openSettings?(.donate) }
        updater.onUpdateFound = { [weak self] release in
            self?.notifications.post(title: String(localized: "Доступна новая версия \(release.version)"),
                                     body: String(localized: "Нажмите, чтобы посмотреть и установить."), kind: .update)
        }
        updater.checkAutomaticallyIfNeeded()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 6 * 3600, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.updater.checkAutomaticallyIfNeeded() }
        }

        watcher.onRename = { [weak self] old, new in
            MainActor.assumeIsolated { self?.handleRename(old: old, new: new) }
        }
        watcher.start(paths: folders)
    }

    // MARK: Настройки

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            Log.error("Автозапуск: \(error)")
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func setAppLanguage(_ code: String) {
        guard code != appLanguage else { return }
        AppLanguage.select(code)
        appLanguage = code
        languageChanged = true
        Log.info("Язык интерфейса: \(code.isEmpty ? "системный" : code)")
    }

    func chooseFolders(prompt: String) -> [String] {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = prompt
        NSApp.activate()
        guard panel.runModal() == .OK else { return [] }
        return panel.urls.map(\.path)
    }

    func addFolders() {
        folders.append(contentsOf: chooseFolders(prompt: String(localized: "Следить")).filter { !folders.contains($0) })
    }

    func addExcludedFolders() {
        excludedFolders.append(contentsOf: chooseFolders(prompt: String(localized: "Исключить")).filter { !excludedFolders.contains($0) })
    }

    func addRule() {
        rules.append(Rule(from: .any, to: .any, action: .ask))
    }

    // MARK: Обработка переименований

    private func handleRename(old: String, new: String) {
        guard !paused else { return }
        suppressed = suppressed.filter { Date().timeIntervalSince($0.value) < 5 }
        guard suppressed[new] == nil else { return }
        guard !excludedFolders.contains(where: { new.hasPrefix($0.hasSuffix("/") ? $0 : $0 + "/") }) else { return }

        let oldName = (old as NSString).lastPathComponent
        let newName = (new as NSString).lastPathComponent
        let from = Formats.fileExtension(of: oldName), to = Formats.fileExtension(of: newName)
        guard let plan = Formats.plan(from: from, to: to) else { return }

        // Картинку проверяем по содержимому: если она уже в нужном формате — делать нечего.
        if plan.engine == .image {
            guard let actual = ImageEngine.actualTypeID(of: URL(fileURLWithPath: new)) else { return }
            if actual == Formats.imageTargetType(to)?.identifier { return }
        }

        let rule = rules.bestMatch(from: from, to: to)
        let keep: Bool
        switch rule?.keepOriginal ?? .inherit {
        case .inherit: keep = keepOriginal
        case .keep: keep = true
        case .discard: keep = false
        }
        let job = ConversionJob(path: new, oldName: oldName, plan: plan, params: params, keepOriginal: keep)
        let action = rule?.action ?? defaultAction
        Log.info("Переименование \(oldName) → \(newName): \(plan.engine), действие \(action.rawValue)")

        switch action {
        case .skip: return
        case .convert: start(job)
        case .ask:
            pendingAsks.append(PendingAsk(job: job))
            askPanel.show()
        }
    }

    // MARK: Вопросы

    func showPendingAsks() {
        if !pendingAsks.isEmpty { askPanel.show() }
    }

    /// Решение по первому вопросу в очереди. `remember` — создать правило для этой пары расширений.
    func resolveAsk(_ ask: PendingAsk, convert: Bool, remember: Bool) {
        pendingAsks.removeAll { $0.id == ask.id }
        if remember {
            rules.append(Rule(from: .ext(ask.job.plan.from), to: .ext(ask.job.plan.to),
                              action: convert ? .convert : .skip,
                              keepOriginal: ask.job.keepOriginal == keepOriginal ? .inherit : (ask.job.keepOriginal ? .keep : .discard)))
        }
        if convert { start(ask.job) }
        if pendingAsks.isEmpty { askPanel.close() }
    }

    // MARK: Конвертация

    private func start(_ job: ConversionJob) {
        let id = job.id
        activeJobs.append(ActiveJob(id: id, title: "\(job.oldName) → \(job.newName)"))
        let task = Task { [weak self] in
            let result: Result<URL?, Error>
            do {
                let trashed = try await Pipeline.run(job) { p in
                    Task { @MainActor in self?.setProgress(p, for: id) }
                }
                result = .success(trashed)
            } catch {
                result = .failure(error)
            }
            self?.finish(job, result)
        }
        if let i = activeJobs.firstIndex(where: { $0.id == id }) { activeJobs[i].task = task }
    }

    func cancel(_ job: ActiveJob) {
        job.task?.cancel()
    }

    /// Общий прогресс для значка в строке меню (`nil` — неизвестен).
    var overallProgress: Double? {
        let known = activeJobs.compactMap(\.progress)
        guard !known.isEmpty, known.count == activeJobs.count else { return nil }
        return known.reduce(0, +) / Double(known.count)
    }

    private func setProgress(_ value: Double, for id: UUID) {
        if let i = activeJobs.firstIndex(where: { $0.id == id }) { activeJobs[i].progress = value }
    }

    private func finish(_ job: ConversionJob, _ result: Result<URL?, Error>) {
        activeJobs.removeAll { $0.id == job.id }
        suppressed[job.path] = Date()

        switch result {
        case .success(let trashed):
            Log.info("Готово: \(job.oldName) → \(job.newName)")
            let entry = HistoryEntry(date: Date(), directory: job.directory, oldName: job.oldName,
                                     newName: job.newName, trashedOriginal: trashed?.path)
            history.insert(entry, at: 0)
            saveHistory()
            lastError = nil
            countConversionForDonationPrompt()
            if notify {
                notifications.post(title: String(localized: "Сконвертировано"), body: "\(job.oldName) → \(job.newName)",
                                   kind: .converted(path: entry.convertedPath))
            }
        case .failure(let error) where Self.isCancellation(error):
            Log.info("Отменено: \(job.oldName) → \(job.newName)")
        case .failure(let error):
            Log.error("\(job.oldName) → \(job.newName) [\(job.plan.engine)]: \(error)")
            lastError = "\(job.newName): \(error.localizedDescription)"
            if notify {
                notifications.post(title: String(localized: "Не удалось сконвертировать \(job.newName)"),
                                   body: error.localizedDescription,
                                   kind: .error(report: "\(job.oldName) → \(job.newName)\n\(error.localizedDescription)"))
            }
        }
    }

    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        let ns = error as NSError
        return (ns.domain == AVFoundationErrorDomain && ns.code == AVError.operationCancelled.rawValue)
            || (ns.domain == NSCocoaErrorDomain && ns.code == NSUserCancelledError)
    }

    // MARK: Поддержка проекта

    /// Один раз — и только один — напоминает о поддержке после N успешных конвертаций.
    private func countConversionForDonationPrompt() {
        let count = defaults.integer(forKey: Keys.conversions) + 1
        defaults.set(count, forKey: Keys.conversions)
        guard Donation.isConfigured, count >= Donation.promptAfterConversions,
              !defaults.bool(forKey: Keys.donatePrompted) else { return }
        defaults.set(true, forKey: Keys.donatePrompted)
        notifications.post(title: String(localized: "RenameConvert сделал для вас \(count) конвертаций"),
                           body: String(localized: "Если он полезен — поддержите разработку ♥"), kind: .donate)
    }

    // MARK: Отчёт и обновления

    func openReport(draft: String? = nil) {
        reportDraft = draft
        reportWindow.show()
    }

    func showUpdate() {
        if let openSettings {
            openSettings(.about)
        } else {
            NSWorkspace.shared.open(updater.releasesPage)
        }
    }

    // MARK: История

    func canRestore(_ entry: HistoryEntry) -> Bool {
        guard !entry.restored, let trashed = entry.trashedOriginal else { return false }
        return FileManager.default.fileExists(atPath: trashed)
    }

    /// Возвращает оригинал из Корзины, а сконвертированный файл отправляет в Корзину.
    func restore(_ entry: HistoryEntry) {
        guard let trashed = entry.trashedOriginal, let idx = history.firstIndex(of: entry) else { return }
        let fm = FileManager.default
        let original = (entry.directory as NSString).appendingPathComponent(entry.oldName)
        let converted = entry.convertedPath

        if fm.fileExists(atPath: original), original != converted {
            lastError = String(localized: "Не удалось вернуть: в папке уже есть файл \(entry.oldName).")
            return
        }
        suppressed[original] = Date()
        suppressed[converted] = Date()
        do {
            if fm.fileExists(atPath: converted) {
                try fm.trashItem(at: URL(fileURLWithPath: converted), resultingItemURL: nil)
            }
            try fm.moveItem(atPath: trashed, toPath: original)
            history[idx].restored = true
            saveHistory()
            lastError = nil
        } catch {
            lastError = String(localized: "Не удалось вернуть \(entry.oldName): \(error.localizedDescription)")
        }
    }

    func reveal(_ entry: HistoryEntry) {
        let path = entry.restored ? (entry.directory as NSString).appendingPathComponent(entry.oldName) : entry.convertedPath
        if FileManager.default.fileExists(atPath: path) {
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: entry.directory))
        }
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    private func saveHistory() {
        if history.count > 200 { history.removeLast(history.count - 200) }
        save(history, forKey: Keys.history)
    }

    // MARK: Хранение

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }

    private static func load<T: Decodable>(_ type: T.Type, from defaults: UserDefaults, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

/// Уведомления: клик по готовому файлу показывает его в Finder, у ошибки есть кнопка «Сообщить».
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    enum Kind {
        case converted(path: String)
        case error(report: String)
        case update
        case donate
    }

    var onReport: ((String) -> Void)?
    var onUpdate: (() -> Void)?
    var onDonate: (() -> Void)?

    func setUp() {
        // Вне .app-бандла (например, при запуске бинарника из .build) уведомления недоступны.
        guard Bundle.main.bundleIdentifier != nil else { return }
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let report = UNNotificationAction(identifier: "report", title: String(localized: "Сообщить об ошибке"), options: [.foreground])
        center.setNotificationCategories([UNNotificationCategory(identifier: "error", actions: [report], intentIdentifiers: [])])
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func post(title: String, body: String, kind: Kind) {
        guard Bundle.main.bundleIdentifier != nil else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        switch kind {
        case .converted(let path): content.userInfo = ["path": path]
        case .error(let report):
            content.userInfo = ["report": report]
            content.categoryIdentifier = "error"
        case .update: content.userInfo = ["update": true]
        case .donate: content.userInfo = ["donate": true]
        }
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let info = response.notification.request.content.userInfo
        DispatchQueue.main.async { [self] in
            if let path = info["path"] as? String {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
            } else if let report = info["report"] as? String {
                onReport?(report)
            } else if info["update"] != nil {
                onUpdate?()
            } else if info["donate"] != nil {
                onDonate?()
            }
        }
        completionHandler()
    }
}
