// Промо-ролик для Instagram Reels (1080×1920, 30 кадр/с) в стиле обзора «снятого на камеру»:
// экран Mac в перспективе с малой глубиной резкости, плавная камера, жёсткие склейки,
// субтитры короткими кусками на фиолетовой плашке. Звук собирает make-promo.sh по плану рендера.
//
//   promo lines <ru|en>                                   — фразы озвучки: «<сцена>\t<текст>» по строке
//   promo render <ru|en> <shots> <durations.json> <out.mp4> <icon.png>
//        durations.json — длительности фраз (сек) в порядке `lines`; рядом пишется <out.mp4>.plan
//   promo mix <plan> <папка с N.aiff> <whoosh.wav> <click.wav> <out.wav>   — сведение звука по плану

import AppKit
import AVFoundation
import CoreImage
import SwiftUI
import UniformTypeIdentifiers

let W: CGFloat = 1080, H: CGFloat = 1920, FPS = 30
/// Экран Mac, который «снимает» камера.
let SW: CGFloat = 1600, SH: CGFloat = 1000
let prePad = 0.1, gap = 0.12, postPad = 0.25

// MARK: - Тексты

struct Copy {
    let phrases: [[String]]
    let menus: [String]
    let folder: String
    let sidebar: [String]
    let dialog: String
    let keep: String, use: String
    let info: String, kindHEIF: String, kindJPEG: String
    let search: String
    let suggestions: [String]
    let upload: String, wait: String, download: String
    let appMenu: [String]
    let convertedTitle: String
    let offline: String
    let free: String, noSubs: String, price: String
    let bio: String, save: String
    let date: String
}

let copies: [String: Copy] = [
    "ru": Copy(
        phrases: [
            ["Как поменять формат файла проще всего?"],
            ["Просто сменить расширение в названии!"],
            ["Но macOS так не умеет: она только переименует файл, а внутри всё останется по-старому."],
            ["Поэтому обычно всё заканчивается поиском онлайн-конвертера."],
            ["Загружаешь файл, ждёшь, скачиваешь обратно.", "А если файлов двадцать?"],
            ["Эту проблему решает RenameConvert."],
            ["Меняешь расширение на JPG, и файл действительно становится JPG."],
            ["Так же с видео, музыкой, документами и архивами.", "Внутри даже есть FFmpeg."],
            ["Для большого видео он спросит, какой нужен кодек и качество."],
            ["Всё происходит прямо на Маке, файлы никуда не загружаются."],
            ["Ощущение, будто это встроенная функция macOS."],
            ["И да, это бесплатно."],
            ["Ссылка в описании.", "Сохрани, чтобы не потерять."],
        ],
        menus: ["Finder", "Файл", "Правка", "Вид", "Переход", "Окно", "Справка"],
        folder: "Загрузки",
        sidebar: ["Избранное", "Загрузки", "Рабочий стол", "Документы", "Программы", "iCloud Drive"],
        dialog: "Вы действительно хотите изменить расширение с «.HEIC» на «.jpg»?",
        keep: "Оставить .HEIC", use: "Использовать .jpg",
        info: "Тип:", kindHEIF: "Изображение HEIF", kindJPEG: "Изображение JPEG",
        search: "конвертер heic в jpg",
        suggestions: ["конвертер heic в jpg онлайн", "конвертер heic в jpg бесплатно", "конвертер heic в jpg без регистрации",
                      "конвертер heic в png", "конвертер heic в pdf"],
        upload: "Перетащите файлы сюда", wait: "Конвертация… подождите", download: "Скачать",
        appMenu: ["Следит за переименованиями", "Пауза", "Недавние", "IMG_2041.HEIC → IMG_2041.jpg", "Правила…", "Настройки…"],
        convertedTitle: "Сконвертировано",
        offline: "Без интернета",
        free: "Бесплатно", noSubs: "Без подписок и рекламы", price: "0 ₽",
        bio: "Ссылка в описании", save: "Сохрани",
        date: "Вс 11 окт. 13:44"),
    "en": Copy(
        phrases: [
            ["What's the easiest way to change a file's format?"],
            ["Just change the extension in its name!"],
            ["But macOS can't do that: it only renames the file, and the contents stay the same."],
            ["So you end up searching for an online converter."],
            ["Upload, wait, download it back.", "And what if you have twenty files?"],
            ["RenameConvert fixes this."],
            ["Change the extension to JPG, and the file actually becomes a JPG."],
            ["Same with video, music, documents, and archives.", "There's even FFmpeg inside."],
            ["For a big video, it asks which codec and quality you want."],
            ["Everything happens right on your Mac. Nothing gets uploaded."],
            ["It feels like a built-in macOS feature."],
            ["And yes, it's free."],
            ["Link in the description.", "Save this so you don't lose it."],
        ],
        menus: ["Finder", "File", "Edit", "View", "Go", "Window", "Help"],
        folder: "Downloads",
        sidebar: ["Favorites", "Downloads", "Desktop", "Documents", "Applications", "iCloud Drive"],
        dialog: "Are you sure you want to change the extension from “.HEIC” to “.jpg”?",
        keep: "Keep .HEIC", use: "Use .jpg",
        info: "Kind:", kindHEIF: "HEIF Image", kindJPEG: "JPEG image",
        search: "heic to jpg converter",
        suggestions: ["heic to jpg converter online", "heic to jpg converter free", "heic to jpg converter no sign up",
                      "heic to png converter", "heic to pdf converter"],
        upload: "Drop files here", wait: "Converting… please wait", download: "Download",
        appMenu: ["Watching for renames", "Pause", "Recent", "IMG_2041.HEIC → IMG_2041.jpg", "Rules…", "Settings…"],
        convertedTitle: "Converted",
        offline: "Works offline",
        free: "Free", noSubs: "No subscriptions, no ads", price: "$0",
        bio: "Link in the description", save: "Save it",
        date: "Sun Oct 11 1:44 PM"),
]

/// Как русскому голосу произносить английские названия — только для озвучки, не для субтитров.
let pronunciation: [String: [(String, String)]] = [
    "ru": [("RenameConvert", "Ринейм Конверт"), ("macOS", "мак О Эс"), ("Finder", "Файндер"), ("FFmpeg", "эф эф эм пэг"),
           ("HEIC", "хейк"), ("JPG", "джейпег"), ("MKV", "эм ка вэ"), ("WebP", "веб пэ"), ("OGG", "огг")],
    "en": [("RenameConvert", "Rename Convert"), ("FFmpeg", "F F M peg"), ("HEIC", "heek"), ("JPG", "J-peg"),
           ("MKV", "M K V"), ("WebP", "web P"), ("OGG", "ogg")],
]

func spoken(_ text: String, lang: String) -> String {
    (pronunciation[lang] ?? []).reduce(text) { $0.replacingOccurrences(of: $1.0, with: $1.1) }
}

/// Минимальная длительность сцен (сек), чтобы успела анимация.
let minDurations: [Double] = [2.2, 2.6, 4.2, 3.4, 4.2, 2.4, 4.4, 4.0, 3.8, 3.0, 2.6, 2.0, 2.6]

// MARK: - Таймлайн

struct Phrase { let scene: Int; let text: String; let start: Double; let duration: Double }

struct Timeline {
    let sceneStarts: [Double]
    let sceneDurations: [Double]
    let phrases: [Phrase]
    var total: Double { sceneStarts.last! + sceneDurations.last! }

    /// Озвучка одним куском: время фраз [[начало, конец]] берётся из меток слов синтезатора.
    let continuousVoice: Bool

    init(copy: Copy, timings: [[Double]]) {
        let lead = 0.2
        var phrases: [Phrase] = [], firstStart: [Double] = []
        var k = 0
        for (scene, texts) in copy.phrases.enumerated() {
            for text in texts {
                let start = timings[k][0], end = timings[k][1]
                phrases.append(Phrase(scene: scene, text: text, start: start, duration: end - start))
                if firstStart.count == scene { firstStart.append(start) }
                k += 1
            }
        }
        // Склейка — чуть раньше первой фразы сцены; сцена длится до следующей склейки.
        var starts = firstStart.enumerated().map { $0.offset == 0 ? 0 : max(0, $0.element - lead) }
        for i in 1..<starts.count { starts[i] = max(starts[i], starts[i - 1] + 1.2) }
        let end = timings.last![1] + 0.7
        sceneStarts = starts
        sceneDurations = starts.enumerated().map { i, s in (i + 1 < starts.count ? starts[i + 1] : end) - s }
        self.phrases = phrases
        continuousVoice = true
    }

    init(copy: Copy, durations: [Double]) {
        continuousVoice = false
        var starts: [Double] = [], lengths: [Double] = [], phrases: [Phrase] = []
        var t = 0.0, k = 0
        for (scene, texts) in copy.phrases.enumerated() {
            var local = prePad
            for text in texts {
                phrases.append(Phrase(scene: scene, text: text, start: t + local, duration: durations[k]))
                local += durations[k] + gap
                k += 1
            }
            let length = max(minDurations[scene], local - gap + postPad)
            starts.append(t)
            lengths.append(length)
            t += length
        }
        sceneStarts = starts
        sceneDurations = lengths
        self.phrases = phrases
    }
}

// MARK: - Анимация

func clamp(_ x: Double) -> Double { min(max(x, 0), 1) }
func easeOut(_ x: Double) -> Double { 1 - pow(1 - clamp(x), 3) }
func easeInOut(_ x: Double) -> Double { let c = clamp(x); return c < 0.5 ? 4 * c * c * c : 1 - pow(-2 * c + 2, 3) / 2 }
func spring(_ x: Double) -> Double { let c = clamp(x); return 1 - exp(-7 * c) * cos(11 * c) * (1 - c) }
func mix(_ a: CGFloat, _ b: CGFloat, _ p: Double) -> CGFloat { a + (b - a) * CGFloat(p) }
func mixPoint(_ a: CGPoint, _ b: CGPoint, _ p: Double) -> CGPoint { CGPoint(x: mix(a.x, b.x, p), y: mix(a.y, b.y, p)) }

struct Path2D {
    let keys: [(Double, CGPoint)]
    func at(_ t: Double) -> CGPoint {
        guard t > keys[0].0 else { return keys[0].1 }
        for i in 1..<keys.count where t <= keys[i].0 {
            let a = keys[i - 1], b = keys[i]
            return mixPoint(a.1, b.1, easeInOut((t - a.0) / (b.0 - a.0)))
        }
        return keys.last!.1
    }
}

let purple = Color(red: 0.45, green: 0.15, blue: 0.62)
let macBlue = Color(red: 0.0, green: 0.45, blue: 0.98)

func fileIcon(_ ext: String) -> NSImage {
    let img = NSWorkspace.shared.icon(for: UTType(filenameExtension: ext) ?? .data)
    img.size = NSSize(width: 256, height: 256)
    return img
}

let iconCache: [String: NSImage] = {
    var d: [String: NSImage] = [:]
    for e in ["mov", "mp4", "wav", "mp3", "docx", "pdf", "zip", "7z", "json", "gif", "mkv"] { d[e] = fileIcon(e) }
    let finder = NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app")
    finder.size = NSSize(width: 256, height: 256)
    d["finder"] = finder
    return d
}()

// MARK: - Камера: ракурс, фокус, глубина резкости

/// Положение камеры: точка экрана в фокусе, увеличение (1 — экран во всю ширину кадра), наклоны.
struct Camera {
    var focus: CGPoint
    var zoom: CGFloat
    var yaw: Double      // поворот вокруг вертикали, градусы
    var pitch: Double    // наклон вперёд/назад
    var roll: Double
    var focusRadius: CGFloat = 420

    static func lerp(_ a: Camera, _ b: Camera, _ p: Double) -> Camera {
        Camera(focus: mixPoint(a.focus, b.focus, p), zoom: mix(a.zoom, b.zoom, p),
               yaw: a.yaw + (b.yaw - a.yaw) * p, pitch: a.pitch + (b.pitch - a.pitch) * p,
               roll: a.roll + (b.roll - a.roll) * p, focusRadius: mix(a.focusRadius, b.focusRadius, p))
    }
}

/// Плёночное зерно: одна случайная текстура, сдвигаемая каждый кадр.
let grain: NSImage = {
    let size = 512
    var bytes = [UInt8](repeating: 0, count: size * size)
    var seed: UInt64 = 42
    for i in 0..<bytes.count {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        bytes[i] = UInt8(truncatingIfNeeded: seed >> 56)
    }
    let provider = CGDataProvider(data: Data(bytes) as CFData)!
    let cg = CGImage(width: size, height: size, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: size,
                     space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0),
                     provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    return NSImage(cgImage: cg, size: NSSize(width: size, height: size))
}()

struct CameraView<Content: View>: View {
    let camera: Camera
    let frameIndex: Int
    @ViewBuilder let content: Content

    var body: some View {
        let base = W / SW
        let s = base * camera.zoom
        // Поле с запасом вокруг кадра: увеличенный экран обрезается до него ДО 3D-поворота,
        // иначе слой слишком большой и ImageRenderer рисует мусор.
        let padX = W * 0.25, padY = H * 0.25
        let center = CGPoint(x: W / 2 + padX, y: H * 0.42 + padY)
        let anchor = UnitPoint(x: center.x / (W + 2 * padX), y: center.y / (H + 2 * padY))
        let screen = content
            .frame(width: SW, height: SH)
            .scaleEffect(s, anchor: .topLeading)
            .offset(x: center.x - camera.focus.x * s, y: center.y - camera.focus.y * s)
            .frame(width: W + 2 * padX, height: H + 2 * padY, alignment: .topLeading)
            .clipped()
            .rotation3DEffect(.degrees(camera.yaw), axis: (x: 0, y: 1, z: 0), anchor: anchor, perspective: 0.55)
            .rotation3DEffect(.degrees(camera.pitch), axis: (x: 1, y: 0, z: 0), anchor: anchor, perspective: 0.55)
            .rotationEffect(.degrees(camera.roll), anchor: anchor)
            .frame(width: W, height: H)
        ZStack {
            // Тёмная «комната» вокруг ноутбука.
            RadialGradient(colors: [Color(red: 0.16, green: 0.13, blue: 0.12), .black], center: .center, startRadius: 100, endRadius: 1300)
            ForEach(0..<4, id: \.self) { i in
                Circle().fill(Color(red: 1, green: 0.75, blue: 0.45).opacity(0.18)).frame(width: 260).blur(radius: 60)
                    .position(x: [150, 900, 260, 980][i], y: [200, 330, 1650, 1450][i])
            }
            // Резкий экран; малую глубину резкости добавляет Core Image (см. depthOfField).
            screen
        }
        .frame(width: W, height: H)
        .clipped()
    }
}

// MARK: - Экран Mac: обои, строка меню, окна

struct Wallpaper: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.02, green: 0.10, blue: 0.45), Color(red: 0.05, green: 0.35, blue: 0.95),
                                    Color(red: 0.02, green: 0.15, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Ellipse().fill(Color(red: 0.35, green: 0.65, blue: 1).opacity(0.55)).frame(width: 1900, height: 420).blur(radius: 80)
                .rotationEffect(.degrees(-18)).offset(x: 120, y: 160)
            Capsule().fill(.white.opacity(0.85)).frame(width: 2200, height: 5).blur(radius: 2)
                .rotationEffect(.degrees(-18)).offset(x: 160, y: 190)
            Ellipse().fill(Color(red: 0.0, green: 0.05, blue: 0.3).opacity(0.6)).frame(width: 1500, height: 600).blur(radius: 120)
                .offset(x: -500, y: 420)
        }
        .frame(width: SW, height: SH)
        .clipped()
    }
}

/// Правая часть строки меню: значок RenameConvert, Wi‑Fi, батарея, дата — с фиксированной шириной,
/// чтобы курсор и выпадающее меню точно попадали в значок.
let menuGap: CGFloat = 16, dateWidth: CGFloat = 150, batteryWidth: CGFloat = 28, wifiWidth: CGFloat = 22, statusIconWidth: CGFloat = 24
let statusRightEdge: CGFloat = SW - 18 - dateWidth - menuGap - batteryWidth - menuGap - wifiWidth - menuGap
let statusItemX: CGFloat = statusRightEdge - statusIconWidth / 2

struct MenuBar: View {
    let copy: Copy
    var appStatus: String? = nil      // nil — значка нет; "" — только значок; "42%" — значок и проценты
    var offline = false
    var body: some View {
        HStack(spacing: 18) {
            ForEach(Array(copy.menus.enumerated()), id: \.offset) { i, m in
                Text(m).font(.system(size: 15, weight: i == 0 ? .bold : .regular))
            }
            Spacer()
            HStack(spacing: menuGap) {
                HStack(spacing: 4) {
                    if let appStatus {
                        if !appStatus.isEmpty { Text(appStatus).font(.system(size: 14, weight: .semibold)) }
                        // Тот же значок, что у приложения в строке меню.
                        Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 16, weight: .semibold))
                            .frame(width: statusIconWidth)
                    }
                }
                .frame(width: 90, alignment: .trailing)
                Image(systemName: offline ? "wifi.slash" : "wifi").frame(width: wifiWidth)
                Image(systemName: "battery.75percent").frame(width: batteryWidth)
                Text(copy.date).font(.system(size: 15)).lineLimit(1).frame(width: dateWidth, alignment: .trailing)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .frame(width: SW, height: 30)
        .background(.black.opacity(0.18))
    }
}

struct MacWindow<Content: View>: View {
    let title: String
    let frame: CGRect
    var sidebar: [String]? = nil
    @ViewBuilder let content: Content
    var body: some View {
        HStack(spacing: 0) {
            if let sidebar {
                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 8) {
                        ForEach([Color(red: 1, green: 0.37, blue: 0.34), Color(red: 1, green: 0.74, blue: 0.18), Color(red: 0.16, green: 0.8, blue: 0.25)],
                                id: \.self) { Circle().fill($0).frame(width: 12) }
                    }
                    .padding(.bottom, 14)
                    ForEach(Array(sidebar.enumerated()), id: \.offset) { i, item in
                        Text(item).font(.system(size: i == 0 ? 11 : 13, weight: i == 0 ? .semibold : .regular))
                            .foregroundStyle(i == 0 ? .secondary : .primary)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(i == 1 ? RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.08)) : nil)
                    }
                    Spacer()
                }
                .padding(14)
                .frame(width: 190)
                .background(Color(white: 0.93))
            }
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    if sidebar == nil {
                        HStack(spacing: 8) {
                            ForEach([Color(red: 1, green: 0.37, blue: 0.34), Color(red: 1, green: 0.74, blue: 0.18), Color(red: 0.16, green: 0.8, blue: 0.25)],
                                    id: \.self) { Circle().fill($0).frame(width: 12) }
                        }
                    }
                    Image(systemName: "chevron.left").foregroundStyle(.secondary)
                    Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                    Text(title).font(.system(size: 14, weight: .bold))
                    Spacer()
                    Image(systemName: "square.grid.2x2")
                    Image(systemName: "magnifyingglass")
                }
                .font(.system(size: 14))
                .padding(.horizontal, 16)
                .frame(height: 50)
                Divider()
                content.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(.white)
        }
        .frame(width: frame.width, height: frame.height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
        .position(x: frame.midX, y: frame.midY)
    }
}

struct PhotoThumb: View {
    var size: CGFloat = 96
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Color(red: 1, green: 0.62, blue: 0.35), Color(red: 0.95, green: 0.35, blue: 0.5)], startPoint: .top, endPoint: .bottom)
            Circle().fill(Color(red: 1, green: 0.93, blue: 0.6)).frame(width: size * 0.26).offset(x: size * 0.13, y: -size * 0.33)
            Path { p in
                p.move(to: .init(x: 0, y: size * 0.65)); p.addLine(to: .init(x: size * 0.3, y: size * 0.3))
                p.addLine(to: .init(x: size * 0.52, y: size * 0.52)); p.addLine(to: .init(x: size * 0.72, y: size * 0.26))
                p.addLine(to: .init(x: size, y: size * 0.65)); p.closeSubpath()
            }
            .fill(Color(red: 0.28, green: 0.18, blue: 0.42))
        }
        .frame(width: size, height: size * 0.65)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
    }
}

struct CursorShape: Shape {
    func path(in r: CGRect) -> Path {
        let pts: [(CGFloat, CGFloat)] = [(0, 0), (0, 0.80), (0.22, 0.62), (0.37, 0.95), (0.52, 0.88), (0.38, 0.57), (0.66, 0.57)]
        var p = Path()
        p.addLines(pts.map { CGPoint(x: r.minX + $0.0 * r.width, y: r.minY + $0.1 * r.height) })
        p.closeSubpath()
        return p
    }
}

struct Cursor: View {
    let position: CGPoint
    let clicks: [Double]
    let t: Double
    var body: some View {
        let since = clicks.map { t - $0 }.filter { $0 >= 0 }.min() ?? 99
        CursorShape().fill(.black)
            .overlay(CursorShape().stroke(.white, style: StrokeStyle(lineWidth: 1.6, lineJoin: .round)))
            .frame(width: 16, height: 24)
            .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
            .scaleEffect(since < 0.12 ? 0.82 : 1, anchor: .topLeading)
            .frame(width: 1, height: 1, alignment: .topLeading)
            .position(position)
    }
}

/// Имя файла в Finder: выделение расширения, ввод, курсор ввода.
struct FileName: View {
    let text: String
    var selectedSuffix: String? = nil
    var editing = false
    var selected = false
    var body: some View {
        HStack(spacing: 0) {
            if let suffix = selectedSuffix, text.hasSuffix(suffix) {
                Text(String(text.dropLast(suffix.count))).foregroundStyle(.black)
                Text(suffix).foregroundStyle(.white).background(macBlue)
            } else {
                Text(text).foregroundStyle(selected && !editing ? .white : .black)
                if editing { Rectangle().fill(.black).frame(width: 1.5, height: 15) }
            }
        }
        .font(.system(size: 13))
        .padding(.horizontal, 5).padding(.vertical, 2)
        .background(RoundedRectangle(cornerRadius: 4).fill(selected && !editing ? macBlue : (editing ? .white : .clear)))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(editing ? macBlue : .clear, lineWidth: 2))
    }
}

// MARK: - Субтитры: короткие куски на фиолетовой плашке, как в обзорах

struct Captions: View {
    let phrase: Phrase?
    let t: Double
    var body: some View {
        if let phrase, let chunk = Self.chunk(phrase, t) {
            Text(chunk.uppercased())
                .font(.system(size: 40, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 24).padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(purple))
                .frame(maxWidth: 900)
        }
    }

    /// Фраза делится на куски до ~28 символов; время куска пропорционально его длине.
    static func chunk(_ phrase: Phrase, _ t: Double) -> String? {
        let words = phrase.text.split(separator: " ").map(String.init)
        var chunks: [String] = [], current = ""
        for w in words {
            if !current.isEmpty, current.count + w.count + 1 > 28 { chunks.append(current); current = "" }
            current += current.isEmpty ? w : " " + w
        }
        if !current.isEmpty { chunks.append(current) }
        let total = Double(chunks.reduce(0) { $0 + $1.count })
        var start = phrase.start
        for c in chunks {
            let end = start + phrase.duration * Double(c.count) / total
            if t < end || c == chunks.last { return t >= phrase.start - 0.05 && t < phrase.start + phrase.duration + 0.3 ? c : nil }
            start = end
        }
        return nil
    }
}

// MARK: - Сцены

/// Ракурс сцены: ключевые положения камеры (секунда сцены → камера), между ними — плавный переход.
/// Время -1 означает конец сцены.
struct Shot {
    let keys: [(Double, Camera)]
    init(from: Camera, to: Camera) { keys = [(0, from), (-1, to)] }
    init(keys: [(Double, Camera)]) { self.keys = keys }

    func camera(at t: Double, duration d: Double) -> Camera {
        let ks = keys.map { ($0.0 < 0 ? d : min($0.0, d), $0.1) }
        guard t > ks[0].0 else { return ks[0].1 }
        for i in 1..<ks.count where t <= ks[i].0 {
            let span = max(0.001, ks[i].0 - ks[i - 1].0)
            return Camera.lerp(ks[i - 1].1, ks[i].1, easeInOut((t - ks[i - 1].0) / span))
        }
        return ks.last!.1
    }
}

func cam(_ x: CGFloat, _ y: CGFloat, _ zoom: CGFloat, _ yaw: Double, _ pitch: Double, _ roll: Double, _ radius: CGFloat) -> Camera {
    Camera(focus: CGPoint(x: x, y: y), zoom: zoom, yaw: yaw, pitch: pitch, roll: roll, focusRadius: radius)
}

/// Ракурсы: фокус в координатах экрана 1600×1000.
let photoIcon = CGPoint(x: 605, y: 262), photoLabel = CGPoint(x: 605, y: 330)
let shots: [Shot] = [
    // 0. Макро на имя файла
    Shot(from: cam(640, 320, 3.4, -24, 12, -6, 520), to: cam(620, 318, 3.9, -20, 10, -5, 520)),
    // 1. Ввод расширения
    Shot(from: cam(605, 330, 4.3, 22, 14, 5, 480), to: cam(615, 328, 4.7, 18, 12, 4, 480)),
    // 2. Диалог Finder → «Свойства»: тип всё ещё HEIF
    Shot(keys: [(0, cam(1000, 440, 2.3, -16, 10, -3, 560)), (1.5, cam(1010, 450, 2.4, -14, 9, -3, 560)),
                (2.1, cam(800, 545, 2.5, -12, 8, -2, 560)), (-1, cam(790, 550, 2.6, -12, 8, -2, 560))]),
    // 3. Поиск онлайн-конвертера: текст запроса и подсказки
    Shot(from: cam(640, 380, 2.3, 18, 8, 3, 600), to: cam(650, 400, 2.5, 14, 7, 2, 600)),
    // 4. Загрузка, ожидание, «а если файлов двадцать?»
    Shot(from: cam(800, 420, 2.2, -20, 12, -4, 600), to: cam(800, 480, 1.5, -14, 10, -3, 720)),
    // 5. Значок в строке меню и меню приложения
    Shot(from: cam(1330, 40, 3.0, 20, 16, 4, 520), to: cam(1420, 170, 2.6, 16, 14, 3, 560)),
    // 6. Переименование с RenameConvert: имя → диалог → «Свойства»: теперь JPEG
    Shot(keys: [(0, cam(600, 330, 2.6, -18, 12, -4, 520)), (1.1, cam(620, 335, 2.6, -17, 11, -4, 520)),
                (1.5, cam(1040, 470, 2.3, -15, 10, -3, 560)), (2.3, cam(1040, 470, 2.3, -14, 10, -3, 560)),
                (2.8, cam(800, 545, 2.5, -13, 9, -3, 560)), (-1, cam(790, 550, 2.6, -12, 8, -2, 560))]),
    // 7. Форматы
    Shot(from: cam(600, 300, 2.0, 16, 10, 3, 640), to: cam(620, 560, 2.0, 12, 8, 2, 640)),
    // 8. Окно-вопрос: от центра к кнопке
    Shot(from: cam(1300, 300, 2.0, -20, 10, -4, 620), to: cam(1400, 500, 2.3, -16, 9, -3, 600)),
    // 9. Строка меню без Wi‑Fi
    Shot(from: cam(1290, 25, 4.0, 18, 18, 4, 480), to: cam(1320, 30, 3.6, 14, 16, 3, 500)),
    // 10. Общий план
    Shot(from: cam(800, 500, 1.25, -12, 8, -2, 760), to: cam(800, 470, 1.45, -6, 6, -1, 760)),
    // 11. Бесплатно
    Shot(from: cam(800, 480, 2.0, 10, 8, 2, 640), to: cam(800, 480, 2.25, 6, 6, 1, 640)),
    // 12. Финал
    Shot(from: cam(800, 470, 1.7, -8, 6, -1, 700), to: cam(800, 470, 1.9, -4, 4, 0, 700)),
]

struct ScreenScene: View {
    let scene: Int, t: Double, d: Double
    let copy: Copy
    let shots: [String: NSImage]
    let appIcon: NSImage

    var body: some View {
        ZStack(alignment: .topLeading) {
            Wallpaper()
            content
            MenuBar(copy: copy, appStatus: menuStatus, offline: scene == 9)
                .position(x: SW / 2, y: 15)
        }
        .frame(width: SW, height: SH)
        .environment(\.colorScheme, .light)
    }

    var menuStatus: String? {
        guard scene >= 5 else { return nil }
        if scene == 9 { return t < 1.4 ? "\(Int(clamp(t / 1.4) * 100))%" : "" }
        return ""
    }

    @ViewBuilder var content: some View {
        switch scene {
        case 0: finder(state: .selected)
        case 1: finder(state: .typing)
        case 2: finder(state: .macOSOnlyRenames)
        case 3: browserSearch
        case 4: browserUpload
        case 5: appMenu
        case 6: finder(state: .converts)
        case 7: montage
        case 8: askPanel
        case 9: finder(state: .done)
        case 10: finder(state: .done)
        case 11: freeCard
        default: cta
        }
    }

    // MARK: Finder

    enum FinderState { case selected, typing, macOSOnlyRenames, converts, done }

    func finder(state: FinderState) -> some View {
        let window = CGRect(x: 300, y: 100, width: 1060, height: 680)
        let others: [(String, String)] = [("clip", "mov"), ("song", "wav"), ("report", "docx"), ("backup", "zip"), ("data", "json"), ("trailer", "mkv"), ("notes", "pdf")]
        // Сценарии времени внутри сцены.
        let typed = ["IMG_2041.HEIC", "IMG_2041.", "IMG_2041.j", "IMG_2041.jp", "IMG_2041.jpg"]
        var name = "IMG_2041.HEIC", suffix: String? = nil, editing = false, selected = true
        var dialog = 0.0, converted = false, info: (String, Bool)? = nil
        var cursorKeys: [(Double, CGPoint)] = [(0, CGPoint(x: 700, y: 420))]
        var clicks: [Double] = []
        let useButton = CGPoint(x: 1090, y: 496)
        switch state {
        case .selected:
            cursorKeys = [(0, CGPoint(x: 760, y: 420)), (1.0, CGPoint(x: 640, y: 335))]
            clicks = [1.1]
            editing = t > 1.15
            suffix = t > 1.15 ? ".HEIC".dropFirst().description : nil
        case .typing:
            let step = min(typed.count - 1, max(0, Int((t - 0.3) / 0.22)))
            name = typed[step]; editing = true
            suffix = step == 0 ? "HEIC" : nil
            cursorKeys = [(0, CGPoint(x: 640, y: 338))]
        case .macOSOnlyRenames:
            name = "IMG_2041.jpg"
            dialog = clamp(t / 0.25) * (1 - clamp((t - 1.5) / 0.15))
            cursorKeys = [(0, CGPoint(x: 700, y: 560)), (1.3, useButton)]
            clicks = [1.4]
            editing = t < 1.5
            if t > 1.7 { info = (copy.kindHEIF, false) }
        case .converts:
            let typedAt = min(typed.count - 1, max(0, Int((t - 0.2) / 0.18)))
            name = typed[typedAt]; editing = t < 1.2
            suffix = typedAt == 0 ? "HEIC" : nil
            dialog = clamp((t - 1.2) / 0.2) * (1 - clamp((t - 2.25) / 0.15))
            cursorKeys = [(0, CGPoint(x: 640, y: 338)), (1.2, CGPoint(x: 700, y: 500)), (2.05, useButton), (3.4, CGPoint(x: 1000, y: 620))]
            clicks = [2.15]
            converted = t > 2.4
            if t > 2.6 { info = (copy.kindJPEG, true) }
            if t > 2.3 { name = "IMG_2041.jpg" }
        case .done:
            name = "IMG_2041.jpg"; converted = true; selected = false
            cursorKeys = [(0, CGPoint(x: 1000, y: 650))]
        }

        return ZStack(alignment: .topLeading) {
            MacWindow(title: copy.folder, frame: window, sidebar: copy.sidebar) {
                ZStack(alignment: .topLeading) {
                    // Сетка 4×2: первое — фото.
                    ForEach(0..<8, id: \.self) { i in
                        let col = i % 4, row = i / 4
                        let x = 105 + CGFloat(col) * 210, y = 112 + CGFloat(row) * 230
                        VStack(spacing: 10) {
                            if i == 0 {
                                PhotoThumb()
                                    .overlay(alignment: .bottomTrailing) {
                                        if converted {
                                            Text("JPG").font(.system(size: 10, weight: .heavy)).foregroundStyle(.white)
                                                .padding(.horizontal, 4).padding(.vertical, 1)
                                                .background(Capsule().fill(.green)).offset(x: 6, y: 6)
                                        }
                                    }
                                    .frame(height: 96)
                                FileName(text: name, selectedSuffix: suffix, editing: editing, selected: selected)
                            } else {
                                Image(nsImage: iconCache[others[i - 1].1]!).resizable().frame(width: 96, height: 96)
                                FileName(text: "\(others[i - 1].0).\(others[i - 1].1)")
                            }
                        }
                        .position(x: x, y: y)
                    }
                    // Диалог Finder о смене расширения.
                    if dialog > 0 {
                        VStack(spacing: 12) {
                            Image(nsImage: iconCache["finder"]!).resizable().frame(width: 52, height: 52)
                            Text(copy.dialog).font(.system(size: 13, weight: .bold)).multilineTextAlignment(.center).foregroundStyle(.black)
                            HStack(spacing: 10) {
                                Text(copy.keep).font(.system(size: 13)).foregroundStyle(.black)
                                    .frame(width: 150, height: 28).background(RoundedRectangle(cornerRadius: 7).fill(Color(white: 0.9)))
                                Text(copy.use).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                                    .frame(width: 150, height: 28).background(RoundedRectangle(cornerRadius: 7).fill(macBlue))
                            }
                        }
                        .padding(18)
                        .frame(width: 340)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.97)))
                        .shadow(color: .black.opacity(0.3), radius: 18, y: 8)
                        .scaleEffect(0.9 + 0.1 * spring(dialog))
                        .opacity(dialog)
                        .position(x: 520, y: 290)
                    }
                    // «Свойства» файла — тип по содержимому.
                    if let info {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("IMG_2041.jpg").font(.system(size: 13, weight: .bold)).foregroundStyle(.black)
                            HStack(spacing: 6) {
                                Text(copy.info).foregroundStyle(.secondary)
                                Text(info.0).fontWeight(.semibold).foregroundStyle(info.1 ? Color.green : Color.red)
                                Image(systemName: info.1 ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(info.1 ? Color.green : Color.red)
                            }
                            .font(.system(size: 13))
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.white))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(info.1 ? Color.green : Color.red, lineWidth: 2))
                        .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
                        .position(x: 300, y: 400)
                    }
                }
            }
            Cursor(position: Path2D(keys: cursorKeys).at(t), clicks: clicks, t: t)
        }
    }

    // MARK: Браузер

    var browserFrame: CGRect { CGRect(x: 230, y: 70, width: 1140, height: 820) }

    func browserChrome<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let f = browserFrame
        return VStack(spacing: 0) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    ForEach([Color(red: 1, green: 0.37, blue: 0.34), Color(red: 1, green: 0.74, blue: 0.18), Color(red: 0.16, green: 0.8, blue: 0.25)],
                            id: \.self) { Circle().fill($0).frame(width: 12) }
                }
                Text(copy.search).font(.system(size: 13)).padding(.horizontal, 14).padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(Color(white: 0.9))
            content().frame(maxWidth: .infinity, maxHeight: .infinity).background(.white)
        }
        .frame(width: f.width, height: f.height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
        .position(x: f.midX, y: f.midY)
    }

    var browserSearch: some View {
        // Печать и подсказки укладываются в сцену: в короткой сцене буквы идут быстрее.
        let perChar = min(0.06, max(0.02, d * 0.45) / Double(copy.search.count))
        let chars = min(copy.search.count, max(0, Int((t - 0.15) / perChar)))
        let query = String(copy.search.prefix(chars))
        let typedBy = 0.15 + perChar * Double(copy.search.count)
        let perSuggestion = min(0.15, max(0.05, d - typedBy - 0.4) / Double(copy.suggestions.count))
        let shown = min(copy.suggestions.count, max(0, Int((t - typedBy * 0.6) / perSuggestion)))
        return browserChrome {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    Text(query).foregroundStyle(.black)
                    Rectangle().fill(.black).frame(width: 1.5, height: 18)
                    Spacer()
                }
                .font(.system(size: 18))
                .padding(.horizontal, 18).frame(height: 50)
                Divider()
                ForEach(0..<shown, id: \.self) { i in
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        Text(copy.suggestions[i]).foregroundStyle(.black)
                        Spacer()
                    }
                    .font(.system(size: 16, weight: i == 0 ? .semibold : .regular))
                    .padding(.horizontal, 18).frame(height: 40)
                    .background(i == 0 ? Color(white: 0.94) : .clear)
                }
            }
            .frame(width: 640)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white).shadow(color: .black.opacity(0.18), radius: 12, y: 4))
            .padding(.top, 170)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    var browserUpload: some View {
        let second = t > 2.3   // «а если файлов двадцать?»
        return ZStack(alignment: .topLeading) {
            browserChrome {
                VStack(spacing: 26) {
                    RoundedRectangle(cornerRadius: 16).stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .foregroundStyle(.secondary)
                        .frame(width: 560, height: 200)
                        .overlay {
                            VStack(spacing: 12) {
                                PhotoThumb(size: 70)
                                Text(copy.upload).font(.system(size: 16)).foregroundStyle(.secondary)
                            }
                        }
                    let p = clamp(t / 2.0) * 0.72
                    VStack(alignment: .leading, spacing: 8) {
                        Text(copy.wait).font(.system(size: 15)).foregroundStyle(.black)
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(white: 0.9)).frame(width: 560, height: 12)
                            Capsule().fill(macBlue).frame(width: 560 * p, height: 12)
                        }
                    }
                    Text(copy.download).font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 30).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.75)))
                    // Реклама — типичный онлайн-конвертер.
                    HStack(spacing: 14) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 8).fill(Color(red: 1, green: 0.9, blue: 0.75))
                                .frame(width: 176, height: 90)
                                .overlay(Text("AD").font(.system(size: 22, weight: .black)).foregroundStyle(.orange))
                        }
                    }
                }
                .padding(.top, 70)
                .frame(maxHeight: .infinity, alignment: .top)
            }
            // Двадцать файлов падают поверх — «а если их много?»
            if second {
                ForEach(0..<20, id: \.self) { i in
                    let p = spring((t - 2.3 - 0.04 * Double(i)) / 0.5)
                    PhotoThumb(size: 120)
                        .rotationEffect(.degrees(Double((i * 37) % 30) - 15))
                        .scaleEffect(max(0.01, p))
                        .opacity(clamp(p * 2))
                        .position(x: 420 + CGFloat((i * 173) % 760), y: 260 + CGFloat((i * 97) % 420))
                }
            }
        }
    }

    // MARK: Приложение

    var appMenu: some View {
        let open = t > 0.7
        let icon = CGPoint(x: statusItemX, y: 15)
        return ZStack(alignment: .topLeading) {
            if open {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 10) {
                        Image(nsImage: appIcon).resizable().frame(width: 28, height: 28)
                        Text("RenameConvert").font(.system(size: 14, weight: .bold))
                    }
                    .padding(.bottom, 8)
                    ForEach(Array(copy.appMenu.enumerated()), id: \.offset) { i, item in
                        if i == 2 { Divider().padding(.vertical, 4) }
                        Text(item)
                            .font(.system(size: i == 2 ? 11 : 13, weight: i == 2 ? .semibold : .regular))
                            .foregroundStyle(i == 0 || i == 2 ? Color.secondary : Color.primary)
                            .padding(.vertical, 4).padding(.horizontal, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(i == 3 ? RoundedRectangle(cornerRadius: 5).fill(macBlue.opacity(0.85)) : nil)
                            .foregroundStyle(i == 3 ? .white : .primary)
                    }
                }
                .padding(12)
                .frame(width: 300)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.96)))
                .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
                .scaleEffect(0.9 + 0.1 * spring((t - 0.7) / 0.4), anchor: .topTrailing)
                .position(x: min(icon.x - 12 + 150, SW - 8 - 150), y: 34 + 150)
            }
            Cursor(position: Path2D(keys: [(0, CGPoint(x: icon.x - 80, y: 160)), (0.6, CGPoint(x: icon.x + 4, y: 18))]).at(t), clicks: [0.65], t: t)
        }
    }

    var montage: some View {
        let rows = [("clip", "mov", "mp4"), ("clip", "mov", "gif"), ("song", "wav", "mp3"), ("report", "docx", "pdf"), ("trailer", "mkv", "mp4"), ("photos", "zip", "7z")]
        let frame = CGRect(x: 380, y: 110, width: 840, height: 720)
        return ZStack(alignment: .topLeading) {
            MacWindow(title: copy.folder, frame: frame) {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { i, r in
                        let at = 0.25 + 0.4 * Double(i)
                        let p = easeInOut((t - at) / 0.25)
                        HStack(spacing: 14) {
                            Image(nsImage: iconCache[p > 0.5 ? r.2 : r.1]!).resizable().frame(width: 60, height: 60)
                            HStack(spacing: 0) {
                                Text("\(r.0).").foregroundStyle(.black)
                                ZStack(alignment: .leading) {
                                    Text(r.1).foregroundStyle(.black).offset(y: -26 * p).opacity(1 - p)
                                    Text(r.2).foregroundStyle(macBlue).offset(y: 26 * (1 - p)).opacity(p)
                                }
                                .clipped()
                            }
                            .font(.system(size: 26, weight: .semibold))
                            Spacer()
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 30)).foregroundStyle(.green)
                                .scaleEffect(spring((t - at - 0.2) / 0.4))
                        }
                        .padding(.horizontal, 28)
                        .frame(height: 110)
                        .background(i % 2 == 1 ? Color(white: 0.965) : .white)
                    }
                }
            }
            // Значок FFmpeg — к словам «внутри даже есть FFmpeg».
            if t > d * 0.6 {
                Text("FFmpeg").font(.system(size: 34, weight: .black, design: .rounded)).foregroundStyle(.white)
                    .padding(.horizontal, 22).padding(.vertical, 10)
                    .background(Capsule().fill(Color(red: 0.0, green: 0.55, blue: 0.25)))
                    .shadow(radius: 10)
                    .scaleEffect(spring((t - d * 0.6) / 0.4))
                    .position(x: 800, y: 520)
            }
        }
    }

    var askPanel: some View {
        let image = shots["ask"]!
        let width: CGFloat = 520
        let height = width * image.size.height / image.size.width
        let center = CGPoint(x: SW - 40 - width / 2, y: 50 + height / 2)
        let button = CGPoint(x: center.x - width / 2 + 0.895 * width, y: center.y - height / 2 + 0.94 * height)
        let slide = easeOut(t / 0.4)
        let click = max(2.0, d - 1.2)
        return ZStack(alignment: .topLeading) {
            finder(state: .done)
            Image(nsImage: image).resizable().frame(width: width, height: height)
                .background(Color(white: 0.965))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
                .position(x: center.x + 400 * (1 - slide), y: center.y)
                .opacity(1 - clamp((t - click - 0.1) / 0.2))
            Cursor(position: Path2D(keys: [(0, CGPoint(x: 900, y: 700)), (click - 0.1, button)]).at(t), clicks: [click], t: t)
        }
    }

    var freeCard: some View {
        ZStack {
            VStack(spacing: 16) {
                Image(nsImage: appIcon).resizable().frame(width: 120, height: 120)
                Text("RenameConvert").font(.system(size: 34, weight: .heavy)).foregroundStyle(.black)
                Text(copy.price).font(.system(size: 110, weight: .black)).foregroundStyle(.black)
                    .scaleEffect(1 + 0.25 * (1 - spring(t / 0.5)))
                Text(copy.noSubs).font(.system(size: 20, weight: .medium)).foregroundStyle(.secondary)
            }
            .padding(40)
            .frame(width: 520)
            .background(RoundedRectangle(cornerRadius: 24).fill(.white))
            .shadow(color: .black.opacity(0.35), radius: 30, y: 14)
            Text(copy.free.uppercased())
                .font(.system(size: 54, weight: .black)).foregroundStyle(Color(red: 0.1, green: 0.7, blue: 0.3))
                .padding(.horizontal, 22).padding(.vertical, 6)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.1, green: 0.7, blue: 0.3), lineWidth: 6))
                .rotationEffect(.degrees(-14))
                .scaleEffect(t > 0.35 ? 1 + 0.6 * (1 - easeOut((t - 0.35) / 0.2)) : 0.01)
                .opacity(t > 0.35 ? 1 : 0)
                .offset(x: 150, y: 120)
        }
        .frame(width: SW, height: SH)
    }

    var cta: some View {
        VStack(spacing: 22) {
            Image(nsImage: appIcon).resizable().frame(width: 200, height: 200)
                .scaleEffect(0.7 + 0.3 * spring(t / 0.5))
            Text("RenameConvert").font(.system(size: 64, weight: .black)).foregroundStyle(.white)
            HStack(spacing: 30) {
                Label(copy.bio, systemImage: "link").font(.system(size: 30, weight: .bold))
                Label(copy.save, systemImage: "bookmark.fill").font(.system(size: 30, weight: .bold))
            }
            .foregroundStyle(.white)
            .opacity(easeOut((t - 0.3) / 0.3))
        }
        .frame(width: SW, height: SH)
    }
}

// MARK: - Кадр: сцена с камерой → размытие Core Image → виньетка, зерно, субтитры

struct FrameState {
    let scene: Int, local: Double, d: Double
    let camera: Camera

    init(t: Double, timeline: Timeline) {
        scene = timeline.sceneStarts.lastIndex { $0 <= t } ?? 0
        local = t - timeline.sceneStarts[scene]
        d = timeline.sceneDurations[scene]
        let shot = shotsList[scene]
        var c = shot.camera(at: local, duration: d)
        // «Рывок» камеры на склейке и лёгкая тряска руки.
        c.zoom *= CGFloat(1 + 0.05 * (1 - easeOut(local / 0.3)))
        c.focus.x += CGFloat(sin(t * 1.7) * 4 + sin(t * 3.1) * 2)
        c.focus.y += CGFloat(cos(t * 1.3) * 3)
        camera = c
    }
}

struct SceneLayer: View {
    let state: FrameState, frameIndex: Int
    let copy: Copy
    let shots: [String: NSImage]
    let appIcon: NSImage
    var body: some View {
        CameraView(camera: state.camera, frameIndex: frameIndex) {
            ScreenScene(scene: state.scene, t: state.local, d: state.d, copy: copy, shots: shots, appIcon: appIcon)
        }
    }
}

struct OverlayLayer: View {
    let t: Double, frameIndex: Int
    let timeline: Timeline
    var body: some View {
        ZStack {
            RadialGradient(colors: [.clear, .black.opacity(0.55)], center: UnitPoint(x: 0.5, y: 0.45), startRadius: 520, endRadius: 1250)
            Image(nsImage: grain).resizable(resizingMode: .tile)
                .frame(width: W + 512, height: H + 512)
                .offset(x: CGFloat((frameIndex * 137) % 512) - 256, y: CGFloat((frameIndex * 311) % 512) - 256)
                .frame(width: W, height: H)
                .clipped()
                .opacity(0.045)
            Captions(phrase: timeline.phrases.last { $0.start <= t + 0.05 }, t: t)
                .position(x: W / 2, y: 1500)
        }
        .frame(width: W, height: H)
        .clipped()
    }
}

let ciContext = CIContext(options: [.useSoftwareRenderer: false])

/// Малая глубина резкости: в фокусе резко, к краям размытие нарастает.
func depthOfField(_ image: CGImage, focusRadius: CGFloat) -> CGImage {
    let input = CIImage(cgImage: image)
    let center = CIVector(x: W / 2, y: H * 0.58)            // у Core Image ось Y снизу вверх
    let mask = CIFilter(name: "CIRadialGradient", parameters: [
        "inputCenter": center, "inputRadius0": focusRadius * 0.85, "inputRadius1": focusRadius * 1.8,
        "inputColor0": CIColor.black, "inputColor1": CIColor.white,
    ])!.outputImage!.cropped(to: input.extent)
    let blurred = CIFilter(name: "CIMaskedVariableBlur", parameters: [
        kCIInputImageKey: input.clampedToExtent(), "inputMask": mask, kCIInputRadiusKey: 16,
    ])!.outputImage!.cropped(to: input.extent)
    return ciContext.createCGImage(blurred, from: input.extent)!
}

@MainActor
func renderFrame(t: Double, frameIndex: Int, timeline: Timeline, copy: Copy, shots: [String: NSImage], appIcon: NSImage) -> CGImage? {
    let state = FrameState(t: t, timeline: timeline)
    let sceneRenderer = ImageRenderer(content: SceneLayer(state: state, frameIndex: frameIndex, copy: copy, shots: shots, appIcon: appIcon))
    sceneRenderer.scale = 1
    let overlayRenderer = ImageRenderer(content: OverlayLayer(t: t, frameIndex: frameIndex, timeline: timeline))
    overlayRenderer.scale = 1
    guard let scene = sceneRenderer.cgImage, let overlay = overlayRenderer.cgImage else { return nil }
    let soft = depthOfField(scene, focusRadius: state.camera.focusRadius)
    let ctx = CGContext(data: nil, width: Int(W), height: Int(H), bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)!
    let rect = CGRect(x: 0, y: 0, width: W, height: H)
    ctx.draw(soft, in: rect)
    ctx.draw(overlay, in: rect)
    return ctx.makeImage()
}

let shotsList = shots

// MARK: - Запись

func loadTimeline(copy: Copy, path: String) throws -> Timeline {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    if let timings = try? JSONDecoder().decode([[Double]].self, from: data) { return Timeline(copy: copy, timings: timings) }
    return Timeline(copy: copy, durations: try JSONDecoder().decode([Double].self, from: data))
}

@MainActor
func render(lang: String, shotsDir: String, timingsPath: String, output: URL, iconPath: String) async throws {
    let copy = copies[lang]!
    let timeline = try loadTimeline(copy: copy, path: timingsPath)
    var images: [String: NSImage] = [:]
    for name in ["ask", "history"] { images[name] = NSImage(contentsOfFile: "\(shotsDir)/\(lang)/\(name).png") }
    let appIcon = NSImage(contentsOfFile: iconPath)!

    // План звука: фразы, мягкий «вжух» на склейках, щелчки мыши.
    var plan: [String] = []
    if timeline.continuousVoice {
        plan.append("voice full 0")
    } else {
        for (i, p) in timeline.phrases.enumerated() { plan.append("voice \(i) \(Int(p.start * 1000))") }
    }
    for s in timeline.sceneStarts.dropFirst() { plan.append("whoosh \(Int((s - 0.15) * 1000))") }
    let st = timeline.sceneStarts, sd = timeline.sceneDurations
    for c in [st[0] + 1.1, st[2] + 1.4, st[5] + 0.65, st[6] + 2.15, st[8] + max(2.0, sd[8] - 1.2)] {
        plan.append("click \(Int(c * 1000))")
    }
    plan.append("total \(Int(timeline.total * 1000))")
    try plan.joined(separator: "\n").write(to: output.appendingPathExtension("plan"), atomically: true, encoding: .utf8)

    try? FileManager.default.removeItem(at: output)
    let writer = try AVAssetWriter(outputURL: output, fileType: .mp4)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: Int(W), AVVideoHeightKey: Int(H),
        AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 12_000_000, AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel],
    ])
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
        kCVPixelBufferWidthKey as String: Int(W), kCVPixelBufferHeightKey as String: Int(H),
    ])
    writer.add(input)
    writer.startWriting()
    writer.startSession(atSourceTime: .zero)

    let frames = Int((timeline.total * Double(FPS)).rounded())
    for f in 0..<frames {
        let t = Double(f) / Double(FPS)
        guard let image = renderFrame(t: t, frameIndex: f, timeline: timeline, copy: copy, shots: images, appIcon: appIcon) else { continue }
        while !input.isReadyForMoreMediaData { try await Task.sleep(for: .milliseconds(2)) }
        var buffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
        guard let buffer else { continue }
        CVPixelBufferLockBaseAddress(buffer, [])
        let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: Int(W), height: Int(H), bitsPerComponent: 8,
                            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: W, height: H))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(f), timescale: CMTimeScale(FPS)))
    }
    input.markAsFinished()
    await writer.finishWriting()
    if writer.status != .completed { throw writer.error! }
    print(String(format: "rendered %d frames, %.1f s", frames, timeline.total))
}

// MARK: - Сведение звука (ffmpeg с двумя десятками входов зависает — сводим сами)

func mix(plan: String, voiceDir: String, whoosh: String, click: String, output: String) throws {
    let rate = 48_000.0
    let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 2)!
    var events: [(String, Double)] = []
    var total = 0.0
    for line in try String(contentsOfFile: plan, encoding: .utf8).split(separator: "\n") {
        let f = line.split(separator: " ").map(String.init)
        switch f[0] {
        case "voice": events.append(("\(voiceDir)/\(f[1]).aiff", Double(f[2])! / 1000))
        case "whoosh": events.append((whoosh, Double(f[1])! / 1000))
        case "click": events.append((click, Double(f[1])! / 1000))
        case "total": total = Double(f[1])! / 1000
        default: break
        }
    }
    let frames = AVAudioFrameCount(total * rate)
    let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
    out.frameLength = frames
    for (path, start) in events {
        let file = try AVAudioFile(forReading: URL(fileURLWithPath: path))
        let source = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))!
        try file.read(into: source)
        let converter = AVAudioConverter(from: file.processingFormat, to: format)!
        let capacity = AVAudioFrameCount(Double(source.frameLength) * rate / file.processingFormat.sampleRate) + 1024
        let converted = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity)!
        var fed = false
        var error: NSError?
        converter.convert(to: converted, error: &error) { _, status in
            if fed { status.pointee = .endOfStream; return nil }
            fed = true
            status.pointee = .haveData
            return source
        }
        if let error { throw error }
        let offset = Int(start * rate)
        for ch in 0..<2 {
            let dst = out.floatChannelData![ch], src = converted.floatChannelData![ch]
            for i in 0..<Int(converted.frameLength) where offset + i < Int(frames) && offset + i >= 0 {
                dst[offset + i] += src[i]
            }
        }
    }
    let settings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: rate, AVNumberOfChannelsKey: 2,
                                   AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false]
    let writer = try AVAudioFile(forWriting: URL(fileURLWithPath: output), settings: settings,
                                 commonFormat: .pcmFormatFloat32, interleaved: false)
    try writer.write(from: out)
}

@main
struct Main {
    static func main() async throws {
        let a = CommandLine.arguments
        switch a[1] {
        case "lines":
            for (scene, list) in copies[a[2]]!.phrases.enumerated() {
                for text in list { print("\(scene)\t\(text)") }
            }
        case "spoken":   // promo spoken <lang> — фразы для озвучки (JSON), с произношением названий
            let list = copies[a[2]]!.phrases.flatMap { $0 }.map { spoken($0, lang: a[2]) }
            print(String(data: try JSONEncoder().encode(list), encoding: .utf8)!)
        case "render":
            _ = NSApplication.shared
            try await render(lang: a[2], shotsDir: a[3], timingsPath: a[4], output: URL(fileURLWithPath: a[5]), iconPath: a[6])
        case "frame":   // promo frame <lang> <shots> <durations.json> <t> <out.png> <icon.png> — один кадр для отладки
            _ = NSApplication.shared
            try await MainActor.run {
                let copy = copies[a[2]]!
                let timeline = try loadTimeline(copy: copy, path: a[4])
                var images: [String: NSImage] = [:]
                for name in ["ask", "history"] { images[name] = NSImage(contentsOfFile: "\(a[3])/\(a[2])/\(name).png") }
                let t = Double(a[5])!
                let image = renderFrame(t: t, frameIndex: Int(t * 30), timeline: timeline, copy: copy,
                                        shots: images, appIcon: NSImage(contentsOfFile: a[7])!)!
                let rep = NSBitmapImageRep(cgImage: image)
                try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: a[6]))
            }
        case "mix":
            try mix(plan: a[2], voiceDir: a[3], whoosh: a[4], click: a[5], output: a[6])
        default:
            print("usage: promo lines <lang> | promo render <lang> <shots> <durations.json> <out.mp4> <icon.png> | promo mix …")
        }
    }
}
