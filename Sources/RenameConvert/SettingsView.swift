// Окно настроек: основные, правила, параметры, папки, форматы, история, о программе.

import QuickLookThumbnailing
import SwiftUI
import UniformTypeIdentifiers

enum SettingsTab: Hashable, CaseIterable {
    case general, rules, params, folders, formats, history, about, donate

    var title: LocalizedStringKey {
        switch self {
        case .general: return "Основные"
        case .rules: return "Правила"
        case .params: return "Параметры"
        case .folders: return "Папки"
        case .formats: return "Форматы"
        case .history: return "История"
        case .about: return "О программе"
        case .donate: return "Поддержать"
        }
    }

    var symbol: String {
        switch self {
        case .general: return "gearshape"
        case .rules: return "list.bullet.rectangle"
        case .params: return "slider.horizontal.3"
        case .folders: return "folder"
        case .formats: return "square.grid.2x2"
        case .history: return "clock.arrow.circlepath"
        case .about: return "info.circle"
        case .donate: return "heart"
        }
    }
}

/// Настройки с боковой панелью, как в «Системных настройках»: разделы не прячутся,
/// сколько бы их ни было и какими бы длинными ни были подписи на другом языке.
/// (NavigationSplitView не держит заданную ширину колонки, поэтому раскладка своя.)
struct SettingsView: View {
    static let windowID = "settings"
    @Bindable var model: AppModel

    var body: some View {
        HStack(spacing: 0) {
            List(SettingsTab.allCases, id: \.self, selection: Binding(
                get: { model.settingsTab }, set: { if let tab = $0 { model.settingsTab = tab } })) { tab in
                Label(tab.title, systemImage: tab.symbol)
                    .padding(.vertical, 2)
            }
            .listStyle(.sidebar)
            .frame(width: 210)

            Divider()

            // Минимальная ширина обязательна: без неё длинный текст при расчёте раскладки
            // получает почти нулевую ширину и растягивает раздел на тысячи пунктов в высоту.
            detail
                .frame(minWidth: 620, maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        // Фиксированный размер: иначе таблицы и списки растягивают окно по своей «идеальной» высоте.
        .frame(width: 880, height: 580)
    }

    @ViewBuilder private var detail: some View {
        switch model.settingsTab {
        case .general: GeneralTab(model: model)
        case .rules: RulesTab(model: model)
        case .params:
            Form { ParamsSections(params: $model.params) }
                .formStyle(.grouped)
        case .folders: FoldersTab(model: model)
        case .formats: FormatsTab()
        case .history: HistoryTab(model: model)
        case .about: AboutTab(model: model)
        case .donate: DonateTab()
        }
    }
}

// MARK: - Основные

private struct GeneralTab: View {
    @Bindable var model: AppModel

    var body: some View {
        Form {
            Section {
                Toggle("Конвертировать при смене расширения", isOn: Binding(
                    get: { !model.paused }, set: { model.paused = !$0 }))
                Toggle("Запускать при входе в систему", isOn: Binding(
                    get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) }))
                Toggle("Показывать уведомления", isOn: $model.notify)
            }

            Section("Язык") {
                Picker("Язык интерфейса", selection: Binding(
                    get: { model.appLanguage }, set: { model.setAppLanguage($0) })) {
                    Text("Как в системе").tag("")
                    Divider()
                    ForEach(AppLanguage.all, id: \.code) { Text(verbatim: $0.name).tag($0.code) }
                }
                if model.languageChanged {
                    HStack {
                        Text("Язык изменится после перезапуска.").foregroundStyle(.secondary)
                        Spacer()
                        Button("Перезапустить", action: AppRelauncher.relaunch)
                    }
                }
            }

            Section {
                Picker("Если нет подходящего правила", selection: $model.defaultAction) {
                    ForEach(RuleAction.allCases) { Text($0.title).tag($0) }
                }
                Toggle(isOn: $model.keepOriginal) {
                    Text("Класть оригинал в Корзину")
                    Text("Исходный файл со старым именем можно будет вернуть из Корзины или из истории.")
                }
            } header: {
                Text("Поведение")
            } footer: {
                Text("Отдельные правила для форматов — на вкладке «Правила».")
                    .foregroundStyle(.secondary)
            }

            Section("Как пользоваться") {
                Text("Переименуйте файл в Finder и поменяйте расширение — например, **photo.heic → photo.jpg** или **video.mov → video.mp4**. Подтвердите смену расширения, и файл будет перекодирован. Картинки, видео, аудио, документы, JSON/plist и архивы — список на вкладке «Форматы».")
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Доступ к файлам") {
                Text("При первом обращении к Рабочему столу, Документам или Загрузкам macOS спросит разрешение. Если вы отказали, включите доступ вручную.")
                    .fixedSize(horizontal: false, vertical: true)
                Button("Открыть настройки «Файлы и папки»") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders")!)
                }
            }

            if let error = model.lastError {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Button("Сообщить об ошибке…") { model.openReport(draft: error) }
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Правила

private struct RulesTab: View {
    @Bindable var model: AppModel
    @State private var selection: Rule.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Правило решает, что делать при смене расширения: спросить, конвертировать сразу или ничего не делать. Срабатывает самое конкретное правило (расширение важнее категории). Если ни одно не подошло — действует «\(model.defaultAction.title)» из вкладки «Основные».")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Table($model.rules, selection: $selection) {
                TableColumn("Из") { $rule in SelectorPicker(selection: $rule.from) }
                    .width(105)
                TableColumn("В") { $rule in SelectorPicker(selection: $rule.to) }
                    .width(105)
                TableColumn("Действие") { $rule in
                    Picker("", selection: $rule.action) {
                        ForEach(RuleAction.allCases) { Text($0.title).tag($0) }
                    }
                    .labelsHidden()
                }
                .width(195)
                TableColumn("Оригинал") { $rule in
                    Picker("", selection: $rule.keepOriginal) {
                        ForEach(KeepOriginal.allCases) { Text($0.title).tag($0) }
                    }
                    .labelsHidden()
                }
                .width(160)
            }
            .onDeleteCommand { deleteSelected() }
            .frame(maxHeight: .infinity)
            .overlay {
                if model.rules.isEmpty {
                    ContentUnavailableView("Правил нет", systemImage: "list.bullet.rectangle",
                                           description: Text("Для всех файлов действует поведение по умолчанию."))
                }
            }

            HStack {
                Button("Добавить правило", systemImage: "plus") { model.addRule() }
                Button("Удалить", systemImage: "minus") { deleteSelected() }
                    .disabled(selection == nil)
                Spacer()
                Button("Сбросить к стандартным") { model.rules = Rule.defaults }
            }
        }
        .padding(20)
    }

    private func deleteSelected() {
        model.rules.removeAll { $0.id == selection }
        selection = nil
    }
}

/// Выбор «любой / категория / расширение».
private struct SelectorPicker: View {
    @Binding var selection: RuleSelector

    var body: some View {
        Picker("", selection: $selection) {
            Text("Любой").tag(RuleSelector.any)
            Section("Категории") {
                ForEach(FileCategory.allCases) { Label($0.title, systemImage: $0.symbol).tag(RuleSelector.category($0)) }
            }
            ForEach(FileCategory.allCases) { category in
                Section(category.title) {
                    ForEach(Formats.knownExtensions(in: category), id: \.self) { Text("." + $0).tag(RuleSelector.ext($0)) }
                }
            }
        }
        .labelsHidden()
    }
}

// MARK: - Папки

private struct FoldersTab: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FolderList(title: "Следить за папками",
                       note: "Включая вложенные. Системная «Библиотека» и скрытые папки пропускаются, iCloud Drive и облачные диски — учитываются.",
                       folders: $model.folders,
                       emptyText: "Добавьте хотя бы одну папку, иначе конвертация не сработает.",
                       add: model.addFolders) {
                Button("Только домашняя папка") { model.folders = [NSHomeDirectory()] }
            }
            FolderList(title: "Исключения",
                       note: "Здесь RenameConvert ничего не трогает, даже если папка внутри отслеживаемой.",
                       folders: $model.excludedFolders,
                       emptyText: "Исключений нет.",
                       add: model.addExcludedFolders) { EmptyView() }
        }
        .padding(20)
    }
}

private struct FolderList<Extra: View>: View {
    let title: LocalizedStringKey
    let note: LocalizedStringKey
    @Binding var folders: [String]
    let emptyText: LocalizedStringKey
    let add: () -> Void
    @ViewBuilder let extra: () -> Extra
    @State private var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(note).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            List(selection: $selection) {
                ForEach(folders, id: \.self) { path in
                    HStack(spacing: 10) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text(FileManager.default.displayName(atPath: path))
                        Text((path as NSString).abbreviatingWithTildeInPath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            .listStyle(.bordered(alternatesRowBackgrounds: true))
            .overlay {
                if folders.isEmpty { Text(emptyText).foregroundStyle(.secondary) }
            }
            HStack {
                Button("Добавить…", systemImage: "plus", action: add)
                Button("Удалить", systemImage: "minus") {
                    folders.removeAll { $0 == selection }
                    selection = nil
                }
                .disabled(selection == nil)
                Spacer()
                extra()
            }
        }
    }
}

// MARK: - Форматы

private struct FormatsTab: View {
    private struct Row: Identifiable {
        let id = UUID()
        let category: FileCategory
        let from: String
        let to: String

        init(category: FileCategory, from: String.LocalizationValue, to: String.LocalizationValue) {
            self.category = category
            self.from = String(localized: from)
            self.to = String(localized: to)
        }
    }

    private let rows: [Row] = [
        Row(category: .image, from: "jpg, png, heic, webp, gif, tiff, bmp, RAW (dng, cr2, nef, arw…) и др.",
            to: "\(Formats.allImageTargets.filter { !["jpeg", "tif", "heif"].contains($0) }.joined(separator: ", "))"),
        Row(category: .image, from: "gif", to: "mp4, mov, m4v — анимация в видео"),
        Row(category: .video, from: "\(Formats.allVideoSources.joined(separator: ", "))", to: "\(Formats.allVideoTargets.joined(separator: ", "))"),
        Row(category: .video, from: "видео", to: "gif — анимация; \(Formats.allAudioTargets.joined(separator: ", ")) — звук; jpg, png, heic… — кадр"),
        Row(category: .audio, from: "\(Formats.allAudioSources.joined(separator: ", "))", to: "\(Formats.allAudioTargets.joined(separator: ", "))"),
        Row(category: .document, from: "txt, rtf, html, docx, doc, odt, webarchive, pdf", to: "txt, rtf, html, docx, doc, odt, pdf"),
        Row(category: .document, from: "pdf", to: "jpg, png, heic, tiff… — первая страница"),
        Row(category: .data, from: "json, plist", to: "json, plist"),
        Row(category: .archive, from: "zip, tar, tar.gz, tar.bz2, tar.xz, 7z", to: "zip, tar, tar.gz, tar.bz2, tar.xz, 7z"),
    ]

    var body: some View {
        Form {
            ForEach(FileCategory.allCases) { category in
                Section {
                    ForEach(rows.filter { $0.category == category }) { row in
                        LabeledContent {
                            Text(row.to).multilineTextAlignment(.trailing)
                        } label: {
                            Text(row.from)
                        }
                    }
                } header: {
                    Label(category.title, systemImage: category.symbol)
                }
            }
            Section {
                Text(FFmpeg.isAvailable
                     ? "MP3, WebP, MKV, AVI, WebM, OGG и другие форматы, которых нет в macOS, конвертирует встроенный FFmpeg."
                     : "FFmpeg не найден: MP3, WebP, MKV, AVI, WebM и OGG недоступны.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - История

private struct HistoryTab: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            if model.history.isEmpty {
                ContentUnavailableView("Пока пусто", systemImage: "clock",
                                       description: Text("Здесь появятся файлы, которые RenameConvert сконвертировал."))
            } else {
                List(model.history) { entry in
                    HistoryRow(entry: entry, model: model)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            Divider()
            HStack {
                Text("Записей: \(model.history.count)")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Очистить историю") { model.clearHistory() }
                    .disabled(model.history.isEmpty)
            }
            .padding(12)
        }
    }
}

private struct HistoryRow: View {
    let entry: HistoryEntry
    let model: AppModel
    @State private var thumbnail: NSImage?

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: thumbnail ?? icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .task(id: entry) { thumbnail = await loadThumbnail() }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.oldName).foregroundStyle(entry.restored ? .primary : .secondary)
                    Image(systemName: "arrow.right").font(.caption).foregroundStyle(.tertiary)
                    Text(entry.newName).foregroundStyle(entry.restored ? .secondary : .primary)
                        .strikethrough(entry.restored)
                }
                .lineLimit(1)
                .truncationMode(.middle)
                Text("\(((entry.directory as NSString).standardizingPath as NSString).abbreviatingWithTildeInPath) · \(entry.date, format: .relative(presentation: .named))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }
            Spacer()
            if entry.restored {
                Text("Возвращён").font(.caption).foregroundStyle(.secondary)
            } else if model.canRestore(entry) {
                Button("Вернуть оригинал", systemImage: "arrow.uturn.backward") { model.restore(entry) }
                    .labelStyle(.iconOnly)
                    .help("Вернуть исходный файл из Корзины")
            }
            Button("Показать в Finder", systemImage: "magnifyingglass") { model.reveal(entry) }
                .labelStyle(.iconOnly)
                .help("Показать в Finder")
        }
        .buttonStyle(.borderless)
        .padding(.vertical, 3)
    }

    private var currentName: String { entry.restored ? entry.oldName : entry.newName }

    private var icon: NSImage {
        let type = UTType(filenameExtension: (currentName as NSString).pathExtension) ?? .image
        return NSWorkspace.shared.icon(for: type)
    }

    /// Миниатюра самой картинки через Quick Look.
    private func loadThumbnail() async -> NSImage? {
        let url = URL(fileURLWithPath: entry.directory).appendingPathComponent(currentName)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let request = QLThumbnailGenerator.Request(fileAt: url, size: CGSize(width: 32, height: 32), scale: 2,
                                                   representationTypes: .thumbnail)
        return try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request).nsImage
    }
}

// MARK: - О программе

private struct AboutTab: View {
    let model: AppModel

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 80, height: 80)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RenameConvert").font(.title.bold())
                        Text("Версия \(model.updater.currentVersion)")
                            .foregroundStyle(.secondary)
                        Text("Меняете расширение — меняется формат. Всё локально, файлы никуда не отправляются.")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Обновления") {
                UpdateStatus(updater: model.updater)
                Toggle("Проверять автоматически", isOn: Bindable(model.updater).automatic)
                LabeledContent("Источник") {
                    Link("github.com/\(model.updater.repository)", destination: model.updater.releasesPage)
                }
            }

            Section("Поддержка") {
                Button("Сообщить об ошибке…") { model.openReport() }
                Button("Показать журнал в Finder") { NSWorkspace.shared.activateFileViewerSelecting([Log.url]) }
            }

            Section("Компоненты") {
                LabeledContent("FFmpeg") {
                    Text(FFmpeg.isAvailable ? "встроен (LGPL 2.1), с LAME и libwebp" : "не найден — MP3, WebP, MKV, AVI недоступны")
                        .multilineTextAlignment(.trailing)
                }
                if let licenses = Bundle.main.url(forResource: "Licenses", withExtension: nil) {
                    Button("Лицензии…") { NSWorkspace.shared.open(licenses) }
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct UpdateStatus: View {
    let updater: Updater

    var body: some View {
        switch updater.state {
        case .idle, .upToDate, .failed:
            HStack {
                statusText
                Spacer()
                Button("Проверить обновления") { Task { await updater.check(userInitiated: true) } }
            }
        case .checking:
            HStack {
                Text("Проверяю…").foregroundStyle(.secondary)
                Spacer()
                ProgressView().controlSize(.small)
            }
        case .available(let release):
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Доступна версия \(release.version)", systemImage: "arrow.down.circle.fill")
                        .foregroundStyle(.tint)
                    Spacer()
                    Link("Что нового", destination: release.pageURL)
                    Button("Установить и перезапустить") { Task { await updater.install(release) } }
                        .buttonStyle(.borderedProminent)
                }
                if !release.notes.isEmpty {
                    Text(release.notes)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(6)
                }
            }
        case .installing:
            HStack {
                Text("Скачиваю и устанавливаю…").foregroundStyle(.secondary)
                Spacer()
                ProgressView().controlSize(.small)
            }
        }
    }

    @ViewBuilder private var statusText: some View {
        switch updater.state {
        case .upToDate:
            Label("У вас последняя версия", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
        default:
            if let last = updater.lastCheck {
                Text("Последняя проверка: \(last, format: .relative(presentation: .named))").foregroundStyle(.secondary)
            } else {
                Text("Ещё не проверялось").foregroundStyle(.secondary)
            }
        }
    }
}
