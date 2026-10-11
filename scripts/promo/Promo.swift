// Промо-ролик для Instagram Reels (1080×1920, 30 кадр/с): сценки «как запись экрана»,
// переходы-свайпы, субтитры по словам. Звук собирает make-promo.sh по плану, который пишет этот рендер.
//
//   promo lines <ru|en>                                   — фразы озвучки: «<сцена>\t<текст>» по строке
//   promo render <ru|en> <shots> <durations.json> <out.mp4> <icon.png>
//        durations.json — длительности фраз (сек) в порядке `lines`; рядом пишется <out.mp4>.plan
//   promo mix <plan> <папка с N.aiff> <whoosh.wav> <click.wav> <out.wav>   — сведение звука по плану

import AppKit
import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

let W: CGFloat = 1080, H: CGFloat = 1920, FPS = 30
let swipeDuration = 0.38          // длительность свайпа между сценами
let prePad = 0.12, gap = 0.1, postPad = 0.22

// MARK: - Тексты

struct Copy {
    let phrases: [[String]]                 // по сценам; каждая фраза — отдельный файл озвучки
    let hook: [String]
    let folder: String
    let dialog: (String, String) -> String  // (старое, новое расширение)
    let keep: (String) -> String
    let use: (String) -> String
    let convertedTitle: String
    let restored: String
    let ffmpeg: String
    let features: [(String, String)]
    let free: String
    let bio: String
}

let copies: [String: Copy] = [
    "ru": Copy(
        phrases: [
            ["Хватит гуглить онлайн-конвертеры."],
            ["Просто переименуй файл в Finder — например, HEIC в JPG.", "Готово, это уже настоящий JPG."],
            ["Видео, музыка, документы и архивы — точно так же."],
            ["Внутри FFmpeg, так что MKV, WebP и OGG — тоже не проблема."],
            ["Для тяжёлого видео приложение сначала спросит и даст выбрать качество."],
            ["Передумал? Оригинал вернётся из истории в один клик."],
            ["Всё работает прямо на Маке, без интернета, на двадцати трёх языках."],
            ["RenameConvert. Бесплатно — ссылка в профиле."],
        ],
        hook: ["Онлайн-", "конвертеры?"],
        folder: "Загрузки",
        dialog: { "Изменить расширение с «.\($0)» на «.\($1)»?" },
        keep: { "Оставить .\($0)" },
        use: { "Использовать .\($0)" },
        convertedTitle: "Сконвертировано",
        restored: "Оригинал возвращён",
        ffmpeg: "FFmpeg внутри",
        features: [("wifi.slash", "Без интернета"), ("globe", "23 языка"), ("arrow.down.circle.fill", "Обновляется само")],
        free: "Бесплатно",
        bio: "ссылка в профиле"),
    "en": Copy(
        phrases: [
            ["Stop googling online file converters."],
            ["Just rename a file in Finder — say, HEIC to JPG.", "Done. It's a real JPG now."],
            ["Video, music, documents, and archives work the same way."],
            ["There's FFmpeg inside, so MKV, WebP, and OGG are no problem."],
            ["For big videos, it asks first and lets you pick the quality."],
            ["Changed your mind? Get the original back from History in one click."],
            ["It all runs right on your Mac — offline, in twenty-three languages."],
            ["RenameConvert. It's free — link in bio."],
        ],
        hook: ["Online", "converters?"],
        folder: "Downloads",
        dialog: { "Are you sure you want to change the extension from “.\($0)” to “.\($1)”?" },
        keep: { "Keep .\($0)" },
        use: { "Use .\($0)" },
        convertedTitle: "Converted",
        restored: "Original restored",
        ffmpeg: "FFmpeg inside",
        features: [("wifi.slash", "Works offline"), ("globe", "23 languages"), ("arrow.down.circle.fill", "Updates itself")],
        free: "Free",
        bio: "link in bio"),
]

/// Минимальная длительность сцен (сек), чтобы успела анимация.
let minDurations: [Double] = [1.7, 4.3, 3.0, 2.6, 3.8, 3.2, 2.8, 2.6]
/// Фраза не начнётся раньше этого момента сцены (сцена, фраза) → сек: «Готово» — ровно после клика.
let minPhraseStart: [Int: [Int: Double]] = [1: [1: 2.75]]

// MARK: - Таймлайн

struct Phrase { let scene: Int; let text: String; let start: Double; let duration: Double }

struct Timeline {
    let sceneStarts: [Double]
    let sceneDurations: [Double]
    let phrases: [Phrase]
    var total: Double { sceneStarts.last! + sceneDurations.last! }

    init(copy: Copy, durations: [Double]) {
        var starts: [Double] = [], lengths: [Double] = [], phrases: [Phrase] = []
        var t = 0.0, k = 0
        for (scene, texts) in copy.phrases.enumerated() {
            var local = prePad
            for (i, text) in texts.enumerated() {
                local = max(local, minPhraseStart[scene]?[i] ?? 0)
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

    func localPhraseStart(scene: Int, index: Int) -> Double {
        let list = phrases.filter { $0.scene == scene }
        return index < list.count ? list[index].start - sceneStarts[scene] : 0
    }
}

// MARK: - Анимация

func clamp(_ x: Double) -> Double { min(max(x, 0), 1) }
func easeOut(_ x: Double) -> Double { 1 - pow(1 - clamp(x), 3) }
func easeInOut(_ x: Double) -> Double { let c = clamp(x); return c < 0.5 ? 4 * c * c * c : 1 - pow(-2 * c + 2, 3) / 2 }
func spring(_ x: Double) -> Double { let c = clamp(x); return 1 - exp(-7 * c) * cos(11 * c) * (1 - c) }
func appear(_ t: Double, _ start: Double, _ length: Double = 0.35) -> Double { easeOut((t - start) / length) }

/// Траектория курсора по ключевым точкам.
struct Path2D {
    let keys: [(Double, CGPoint)]
    func at(_ t: Double) -> CGPoint {
        guard t > keys[0].0 else { return keys[0].1 }
        for i in 1..<keys.count where t <= keys[i].0 {
            let a = keys[i - 1], b = keys[i]
            let p = easeInOut((t - a.0) / (b.0 - a.0))
            return CGPoint(x: a.1.x + (b.1.x - a.1.x) * p, y: a.1.y + (b.1.y - a.1.y) * p)
        }
        return keys.last!.1
    }
}

let accent = Color(red: 0.47, green: 0.38, blue: 1.0)
let highlight = Color(red: 1.0, green: 0.84, blue: 0.25)

func icon(_ ext: String) -> NSImage {
    let img = NSWorkspace.shared.icon(for: UTType(filenameExtension: ext) ?? .data)
    img.size = NSSize(width: 512, height: 512)
    return img
}

// MARK: - Общие элементы

struct Wallpaper: View {
    let t: Double
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0.10, blue: 0.30), Color(red: 0.27, green: 0.11, blue: 0.52)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(Color(red: 0.25, green: 0.6, blue: 1).opacity(0.45)).frame(width: 1000).blur(radius: 180)
                .offset(x: -320 + 90 * sin(t / 2.5), y: -650 + 70 * cos(t / 3))
            Circle().fill(Color(red: 0.75, green: 0.3, blue: 0.95).opacity(0.4)).frame(width: 900).blur(radius: 180)
                .offset(x: 330 + 80 * cos(t / 2.8), y: 520 + 90 * sin(t / 3.6))
        }
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

/// Курсор macOS с анимацией клика (нажатие + расходящийся круг).
struct Cursor: View {
    let position: CGPoint
    let clicks: [Double]
    let t: Double
    var body: some View {
        let since = clicks.map { t - $0 }.filter { $0 >= 0 }.min() ?? 99
        let pressed = since < 0.12
        ZStack(alignment: .topLeading) {
            if since < 0.45 {
                Circle().stroke(.white.opacity(0.9 * (1 - since / 0.45)), lineWidth: 5)
                    .frame(width: 30 + 120 * since / 0.45, height: 30 + 120 * since / 0.45)
                    .position(x: 0, y: 0)
            }
            CursorShape().fill(.black)
                .overlay(CursorShape().stroke(.white, style: StrokeStyle(lineWidth: 3.5, lineJoin: .round)))
                .frame(width: 44, height: 64)
                .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                .scaleEffect(pressed ? 0.82 : 1, anchor: .topLeading)
        }
        .frame(width: 1, height: 1, alignment: .topLeading)
        .position(position)
    }
}

/// Окно в стиле macOS с заголовком.
struct Window<Content: View>: View {
    let title: String
    let size: CGSize
    @ViewBuilder let content: Content
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack(spacing: 14) {
                    ForEach([Color(red: 1, green: 0.37, blue: 0.34), Color(red: 1, green: 0.74, blue: 0.18), Color(red: 0.16, green: 0.8, blue: 0.25)],
                            id: \.self) { Circle().fill($0).frame(width: 22) }
                    Spacer()
                }
                Text(title).font(.system(size: 30, weight: .semibold)).foregroundStyle(.black.opacity(0.75))
            }
            .padding(.horizontal, 26)
            .frame(height: 76)
            .background(Color(white: 0.955))
            Divider()
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: size.width, height: size.height)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: .black.opacity(0.45), radius: 50, y: 26)
    }
}

/// Фото-миниатюра (нарисованный пейзаж), чтобы файл выглядел живым.
struct PhotoThumb: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Color(red: 1, green: 0.62, blue: 0.35), Color(red: 0.95, green: 0.35, blue: 0.5)], startPoint: .top, endPoint: .bottom)
            Circle().fill(Color(red: 1, green: 0.93, blue: 0.6)).frame(width: 60).offset(x: 30, y: -80)
            Path { p in p.move(to: .init(x: 0, y: 150)); p.addLine(to: .init(x: 70, y: 70)); p.addLine(to: .init(x: 120, y: 120))
                p.addLine(to: .init(x: 165, y: 60)); p.addLine(to: .init(x: 230, y: 150)); p.closeSubpath() }
                .fill(Color(red: 0.28, green: 0.18, blue: 0.42))
        }
        .frame(width: 230, height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white, lineWidth: 6))
        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
    }
}

struct Toast: View {
    let text: String
    var color: Color = .green
    var body: some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.system(size: 42, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 34).padding(.vertical, 18)
            .background(Capsule().fill(color))
            .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
    }
}

// MARK: - Субтитры по словам

struct Captions: View {
    let phrase: Phrase?
    let t: Double
    var body: some View {
        if let phrase {
            let words = phrase.text.split(separator: " ").map(String.init)
            let total = Double(words.reduce(0) { $0 + $1.count + 1 })
            // Время слова — пропорционально числу букв до него (речь примерно равномерна).
            var acc = 0.0
            let starts: [Double] = words.map { w in defer { acc += Double(w.count + 1) }; return phrase.start + phrase.duration * acc / total }
            let local = t - phrase.start
            FlowText(words: words, starts: starts, t: t)
                .padding(.horizontal, 40).padding(.vertical, 28)
                .background(RoundedRectangle(cornerRadius: 34).fill(.black.opacity(0.5)))
                .opacity(min(easeOut(local / 0.15), easeOut((phrase.start + phrase.duration + 0.35 - t) / 0.2)))
                .frame(width: 980)
        }
    }
}

struct FlowText: View {
    let words: [String], starts: [Double], t: Double
    var body: some View {
        // Раскладка по строкам до ~24 символов — крупно, как в Reels.
        let lines = Self.lines(words)
        VStack(spacing: 6) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack(spacing: 14) {
                    ForEach(line, id: \.self) { i in
                        let since = t - starts[i]
                        let current = since >= 0 && (i + 1 == words.count || t < starts[i + 1])
                        Text(words[i])
                            .font(.system(size: 58, weight: .heavy))
                            .foregroundStyle(current ? highlight : .white)
                            .opacity(since >= -0.02 ? 1 : 0.42)
                            .scaleEffect(current ? 1.06 + 0.08 * (1 - easeOut(since / 0.18)) : 1)
                    }
                }
            }
        }
    }

    static func lines(_ words: [String]) -> [[Int]] {
        var result: [[Int]] = [[]], length = 0
        for (i, w) in words.enumerated() {
            if length + w.count > 24, !result[result.count - 1].isEmpty { result.append([]); length = 0 }
            result[result.count - 1].append(i)
            length += w.count + 1
        }
        return result
    }
}

// MARK: - Сцены

struct SceneContent: View {
    let scene: Int, t: Double, d: Double
    let copy: Copy
    let timeline: Timeline
    let shots: [String: NSImage]
    let appIcon: NSImage

    var body: some View {
        ZStack {
            switch scene {
            case 0: hook
            case 1: renameDemo
            case 2: montage
            case 3: ffmpeg
            case 4: askDemo
            case 5: historyDemo
            case 6: features
            default: cta
            }
        }
        .frame(width: W, height: H)
    }

    // 0. «Онлайн-конвертеры?» — зачёркиваются.
    var hook: some View {
        VStack(spacing: 10) {
            ForEach(Array(copy.hook.enumerated()), id: \.offset) { i, line in
                Text(line).font(.system(size: 132, weight: .black)).foregroundStyle(.white)
                    .scaleEffect(0.6 + 0.4 * spring((t - 0.12 * Double(i)) / 0.5))
                    .opacity(appear(t, 0.12 * Double(i), 0.2))
            }
        }
        .overlay {
            Capsule().fill(Color(red: 1, green: 0.27, blue: 0.3))
                .frame(width: 780 * easeOut((t - 0.55) / 0.3), height: 18)
                .rotationEffect(.degrees(-8))
                .frame(width: 780, alignment: .leading)
        }
        .position(x: W / 2, y: 760)
    }

    // 1. Переименование в Finder: курсор, ввод, диалог, готово.
    var renameDemo: some View {
        let done = timeline.localPhraseStart(scene: 1, index: 1)
        let origin = CGPoint(x: 60, y: 260)                     // левый верх окна
        let photo = CGPoint(x: origin.x + 165, y: origin.y + 76 + 175)
        let label = CGPoint(x: photo.x, y: photo.y + 135)
        // Кнопка «Использовать» в диалоге (измерено по кадру).
        let useButton = CGPoint(x: 684, y: 870)
        let cursor = Path2D(keys: [
            (0.0, CGPoint(x: 900, y: 1300)), (0.5, CGPoint(x: label.x + 30, y: label.y - 5)),
            (1.6, CGPoint(x: label.x + 30, y: label.y - 5)), (done - 0.45, CGPoint(x: useButton.x - 20, y: useButton.y - 8)),
            (done + 0.6, CGPoint(x: useButton.x + 90, y: useButton.y + 140)),
        ])
        let clickName = 0.55, clickUse = done - 0.3
        let typed = ["IMG_2041.HEIC", "IMG_2041.", "IMG_2041.j", "IMG_2041.jp", "IMG_2041.jpg"]
        let step = min(typed.count - 1, max(0, Int((t - 0.85) / 0.16)))
        let editing = t > clickName && t < done - 1.05
        let selecting = editing && t < 0.85
        let dialog = clamp((t - (done - 1.05)) / 0.25) * (1 - clamp((t - clickUse - 0.05) / 0.18))
        let finished = t > done

        let others: [(String, String)] = [("clip", "mov"), ("song", "wav"), ("report", "docx"), ("backup", "zip"), ("data", "json")]
        return ZStack(alignment: .topLeading) {
            Window(title: copy.folder, size: CGSize(width: 960, height: 860)) {
                ZStack(alignment: .topLeading) {
                    // Сетка файлов: первый — фото, остальные — для антуража.
                    ForEach(0..<6, id: \.self) { i in
                        let col = i % 3, row = i / 3
                        VStack(spacing: 18) {
                            Group {
                                if i == 0 {
                                    PhotoThumb()
                                        .overlay(alignment: .bottomTrailing) {
                                            Text(finished ? "JPG" : "HEIC").font(.system(size: 24, weight: .heavy))
                                                .foregroundStyle(.white).padding(.horizontal, 10).padding(.vertical, 4)
                                                .background(Capsule().fill(finished ? .green : .gray)).offset(x: 10, y: 12)
                                        }
                                        .scaleEffect(finished ? 1 + 0.08 * (1 - easeOut((t - done) / 0.4)) : 1)
                                } else {
                                    Image(nsImage: icon(others[i - 1].1)).resizable().frame(width: 190, height: 190)
                                }
                            }
                            .frame(height: 190)
                            if i == 0 {
                                nameField(typed: typed[step], editing: editing, selecting: selecting, finished: finished)
                            } else {
                                Text("\(others[i - 1].0).\(others[i - 1].1)").font(.system(size: 30)).foregroundStyle(.black.opacity(0.8))
                            }
                        }
                        .frame(width: 310)
                        .position(x: 165 + 315 * CGFloat(col), y: 175 + 340 * CGFloat(row) + 60)
                    }
                    // Диалог Finder о смене расширения.
                    if dialog > 0 {
                        Color.black.opacity(0.12 * dialog)
                        VStack(spacing: 26) {
                            Image(nsImage: appIconFinder()).resizable().frame(width: 96, height: 96)
                            Text(copy.dialog("HEIC", "jpg")).font(.system(size: 31, weight: .bold)).multilineTextAlignment(.center)
                                .foregroundStyle(.black)
                            HStack(spacing: 18) {
                                Text(copy.keep("HEIC")).font(.system(size: 28, weight: .medium)).foregroundStyle(.black)
                                    .frame(width: 270, height: 64).background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.9)))
                                Text(copy.use("jpg")).font(.system(size: 28, weight: .semibold)).foregroundStyle(.white)
                                    .frame(width: 270, height: 64).background(RoundedRectangle(cornerRadius: 14).fill(Color.accentColor))
                            }
                        }
                        .padding(36)
                        .frame(width: 640)
                        .background(RoundedRectangle(cornerRadius: 28).fill(Color(white: 0.975)))
                        .shadow(color: .black.opacity(0.35), radius: 30, y: 14)
                        .scaleEffect(0.85 + 0.15 * spring(dialog))
                        .opacity(dialog)
                        .position(x: 480, y: 420)
                    }
                }
            }
            .position(x: W / 2, y: origin.y + 430)
            .scaleEffect(0.92 + 0.08 * spring(t / 0.6))

            if finished {
                Toast(text: "HEIC → JPG")
                    .scaleEffect(spring((t - done) / 0.5))
                    .position(x: W / 2, y: 1210)
            }
            Cursor(position: cursor.at(t), clicks: [clickName, clickUse], t: t)
        }
        .frame(width: W, height: H)
    }

    func appIconFinder() -> NSImage {
        let img = NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app")
        img.size = NSSize(width: 256, height: 256)
        return img
    }

    @ViewBuilder func nameField(typed: String, editing: Bool, selecting: Bool, finished: Bool) -> some View {
        let font = Font.system(size: 30, weight: .medium)
        HStack(spacing: 0) {
            if selecting {
                Text("IMG_2041.").font(font).foregroundStyle(.black)
                Text("HEIC").font(font).foregroundStyle(.white).background(Color.accentColor)
            } else {
                Text(finished ? "IMG_2041.jpg" : typed).font(font).foregroundStyle(.black)
                if editing { Rectangle().fill(.black).frame(width: 3, height: 34) }
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 7).stroke(editing ? Color.accentColor : .clear, lineWidth: 4))
    }

    // 2. Быстрый монтаж: расширения «прокручиваются» как барабан.
    var montage: some View {
        let rows = [("clip", "mov", "mp4"), ("clip", "mov", "gif"), ("song", "wav", "mp3"), ("report", "docx", "pdf"), ("photos", "zip", "7z")]
        return Window(title: copy.folder, size: CGSize(width: 960, height: 880)) {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { i, r in
                    let at = 0.25 + 0.42 * Double(i)
                    let p = easeInOut((t - at) / 0.3)
                    HStack(spacing: 22) {
                        Image(nsImage: icon(p > 0.5 ? r.2 : r.1)).resizable().frame(width: 104, height: 104)
                        HStack(spacing: 0) {
                            Text("\(r.0).").foregroundStyle(.black)
                            ZStack(alignment: .leading) {
                                Text(r.1).foregroundStyle(.black).offset(y: -50 * p).opacity(1 - p)
                                Text(r.2).foregroundStyle(accent).offset(y: 50 * (1 - p)).opacity(p)
                            }
                            .clipped()
                        }
                        .font(.system(size: 46, weight: .semibold))
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 54)).foregroundStyle(.green)
                            .scaleEffect(spring((t - at - 0.25) / 0.4))
                    }
                    .padding(.horizontal, 40)
                    .frame(height: 158)
                    .background(i % 2 == 1 ? Color(white: 0.965) : .white)
                }
            }
        }
        .scaleEffect(0.95 + 0.05 * spring(t / 0.5))
        .position(x: W / 2, y: 690)
    }

    // 3. FFmpeg и форматы.
    var ffmpeg: some View {
        let chips = ["MKV", "WebP", "OGG", "AVI", "MP3", "WebM", "OPUS", "FLV", "WMA", "MPEG-TS", "FLAC", "AVIF"]
        return VStack(spacing: 56) {
            HStack(spacing: 22) {
                Image(systemName: "shippingbox.fill").font(.system(size: 80)).foregroundStyle(highlight)
                Text(copy.ffmpeg).font(.system(size: 92, weight: .black)).foregroundStyle(.white)
            }
            .scaleEffect(0.7 + 0.3 * spring(t / 0.5))
            VStack(spacing: 26) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 24) {
                        ForEach(row * 3..<row * 3 + 3, id: \.self) { i in
                            let p = spring((t - 0.25 - 0.07 * Double(i)) / 0.45)
                            Text(chips[i]).font(.system(size: 54, weight: .heavy, design: .rounded)).foregroundStyle(.black)
                                .padding(.horizontal, 36).padding(.vertical, 20)
                                .background(Capsule().fill(.white))
                                .rotationEffect(.degrees(Double((i * 7) % 9) - 4))
                                .scaleEffect(max(0.01, p)).opacity(clamp(p * 1.5))
                        }
                    }
                }
            }
        }
        .position(x: W / 2, y: 720)
    }

    // 4. Окно-вопрос: выезжает справа, клик «Конвертировать», затем уведомление.
    var askDemo: some View {
        let image = shots["ask"]!
        let size = CGSize(width: 960, height: 960 * image.size.height / image.size.width)
        let center = CGPoint(x: W / 2, y: 140 + size.height / 2)
        let button = CGPoint(x: center.x - size.width / 2 + 0.895 * size.width, y: center.y - size.height / 2 + 0.94 * size.height)
        let click = max(2.0, d - 1.6)
        let slideIn = easeOut(t / 0.45), slideOut = easeInOut((t - click - 0.1) / 0.35)
        let cursor = Path2D(keys: [(0, CGPoint(x: 200, y: 1350)), (0.6, CGPoint(x: 300, y: 1150)),
                                   (click - 0.1, CGPoint(x: button.x - 10, y: button.y - 6)), (click + 1, CGPoint(x: button.x - 120, y: button.y + 220))])
        let progress = clamp((t - click - 0.2) / 0.9)
        return ZStack {
            menuBar(progress: t > click + 0.15 ? progress : nil)
            Image(nsImage: image).resizable().frame(width: size.width, height: size.height)
                .background(Color(white: 0.965))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.45), radius: 40, y: 20)
                .position(x: center.x + 600 * (1 - slideIn) + 700 * slideOut, y: center.y)
            if progress >= 1 {
                notification(title: copy.convertedTitle, body: "holiday.mov → holiday.mp4")
                    .offset(x: 600 * (1 - easeOut((t - click - 1.15) / 0.35)))
                    .position(x: W - 40 - 390, y: 200)
            }
            Cursor(position: cursor.at(t), clicks: [click], t: t)
        }
        .frame(width: W, height: H)
    }

    func menuBar(progress: Double?) -> some View {
        HStack(spacing: 26) {
            Spacer()
            if let progress {
                if progress < 1 {
                    Text("\(Image(systemName: "arrow.triangle.2.circlepath")) \(Int(progress * 100))%")
                } else {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                }
            } else {
                Image(systemName: "questionmark.circle")
            }
            Image(systemName: "wifi")
            Image(systemName: "battery.75percent")
            Text("9:41")
        }
        .font(.system(size: 30, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 36)
        .frame(width: W, height: 64)
        .background(.black.opacity(0.25))
        .position(x: W / 2, y: 32)
    }

    func notification(title: String, body: String) -> some View {
        HStack(spacing: 22) {
            Image(nsImage: appIcon).resizable().frame(width: 84, height: 84)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.system(size: 32, weight: .bold)).foregroundStyle(.black)
                Text(body).font(.system(size: 28)).foregroundStyle(.black.opacity(0.7))
            }
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(width: 780)
        .background(RoundedRectangle(cornerRadius: 28).fill(Color(white: 0.97)))
        .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
    }

    // 5. История: клик по «вернуть оригинал».
    var historyDemo: some View {
        let image = shots["history"]!
        let size = CGSize(width: 960, height: 960 * image.size.height / image.size.width)
        let center = CGPoint(x: W / 2, y: 720)
        let undo = CGPoint(x: center.x - size.width / 2 + 0.912 * size.width, y: center.y - size.height / 2 + 0.052 * size.height)
        let click = max(1.5, d - 1.5)
        // Лёгкий наезд камеры по центру строки: окно почти во всю ширину кадра.
        let zoom = 1 + 0.1 * easeInOut((t - 0.35) / max(0.4, click - 0.6))
        let anchor = CGPoint(x: W / 2, y: undo.y)
        let target = CGPoint(x: anchor.x + (undo.x - anchor.x) * 1.1, y: undo.y)
        let cursor = Path2D(keys: [(0, CGPoint(x: 300, y: 1400)), (click - 0.1, CGPoint(x: target.x - 8, y: target.y - 6)),
                                   (click + 1.2, CGPoint(x: target.x - 140, y: target.y + 260))])
        return ZStack {
            ZStack {
                Window(title: "RenameConvert", size: CGSize(width: size.width, height: size.height + 76)) {
                    Image(nsImage: image).resizable().frame(width: size.width, height: size.height)
                }
                .scaleEffect(0.94 + 0.06 * spring(t / 0.55))
                .position(x: center.x, y: center.y - 38)
            }
            .frame(width: W, height: H)
            // Камера наезжает на кнопку «вернуть» — она остаётся на месте, остальное увеличивается.
            .scaleEffect(zoom, anchor: UnitPoint(x: anchor.x / W, y: anchor.y / H))
            if t > click {
                Toast(text: copy.restored)
                    .scaleEffect(spring((t - click) / 0.5))
                    .position(x: W / 2, y: center.y + size.height / 2 + 80)
            }
            Cursor(position: cursor.at(t), clicks: [click], t: t)
        }
        .frame(width: W, height: H)
    }

    // 6. Преимущества.
    var features: some View {
        VStack(alignment: .leading, spacing: 50) {
            ForEach(Array(copy.features.enumerated()), id: \.offset) { i, f in
                let p = spring((t - 0.15 - 0.3 * Double(i)) / 0.5)
                HStack(spacing: 36) {
                    Image(systemName: f.0).font(.system(size: 72, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 150, height: 150).background(Circle().fill(accent))
                    Text(f.1).font(.system(size: 76, weight: .heavy)).foregroundStyle(.white)
                }
                .scaleEffect(max(0.01, p), anchor: .leading)
                .opacity(clamp(p * 1.4))
            }
        }
        .frame(width: 900, alignment: .leading)
        .position(x: W / 2, y: 720)
    }

    // 7. Финал.
    var cta: some View {
        VStack(spacing: 40) {
            Image(nsImage: appIcon).resizable().frame(width: 380, height: 380)
                .scaleEffect(0.6 + 0.4 * spring(t / 0.6))
                .rotationEffect(.degrees(-10 * (1 - easeOut(t / 0.6))))
            Text("RenameConvert").font(.system(size: 100, weight: .black)).foregroundStyle(.white)
            HStack(spacing: 18) {
                Text(copy.free).font(.system(size: 46, weight: .heavy)).foregroundStyle(.black)
                    .padding(.horizontal, 30).padding(.vertical, 14).background(Capsule().fill(highlight))
                Text("↓ \(copy.bio)").font(.system(size: 46, weight: .bold)).foregroundStyle(.white)
            }
            .opacity(appear(t, 0.35))
            Text("github.com/Kohinor46/RenameConvert").font(.system(size: 34, weight: .semibold)).foregroundStyle(.white.opacity(0.75))
                .opacity(appear(t, 0.55))
        }
        .position(x: W / 2, y: 720)
    }
}

// MARK: - Кадр: фон, сцены со свайпами, субтитры

struct Frame: View {
    let t: Double
    let timeline: Timeline
    let copy: Copy
    let shots: [String: NSImage]
    let appIcon: NSImage

    var body: some View {
        ZStack {
            Wallpaper(t: t)
            ForEach(visibleScenes(), id: \.scene) { item in
                SceneContent(scene: item.scene, t: max(0, t - timeline.sceneStarts[item.scene]),
                             d: timeline.sceneDurations[item.scene], copy: copy, timeline: timeline, shots: shots, appIcon: appIcon)
                    .offset(y: item.offset)
                    .scaleEffect(item.scale)
                    .blur(radius: item.blur)
                    .opacity(item.opacity)
            }
            Captions(phrase: timeline.phrases.last { $0.start <= t + 0.05 && t < $0.start + $0.duration + 0.4 }, t: t)
                .position(x: W / 2, y: 1500)
        }
        .frame(width: W, height: H)
        .clipped()
        .environment(\.colorScheme, .light)
    }

    struct Item { let scene: Int; let offset: CGFloat; let scale: CGFloat; let blur: CGFloat; let opacity: Double }

    /// Свайп вверх: уходящая сцена уезжает вверх и размывается, новая выезжает снизу.
    func visibleScenes() -> [Item] {
        let starts = timeline.sceneStarts
        for k in 1..<starts.count where abs(t - starts[k]) < swipeDuration / 2 {
            let begin: Double = starts[k] - swipeDuration / 2
            let p: Double = easeInOut((t - begin) / swipeDuration)
            let q = CGFloat(p), r = CGFloat(1 - p)
            let out = Item(scene: k - 1, offset: -H * 0.35 * q, scale: 1 - 0.08 * q, blur: 18 * q, opacity: 1 - p)
            let incoming = Item(scene: k, offset: H * 0.35 * r, scale: 0.92 + 0.08 * q, blur: 18 * r, opacity: p)
            return [out, incoming]
        }
        let current = starts.lastIndex { $0 <= t } ?? 0
        return [Item(scene: current, offset: 0, scale: 1, blur: 0, opacity: 1)]
    }
}

// MARK: - Запись

@MainActor
func render(lang: String, shotsDir: String, durations: [Double], output: URL, iconPath: String) async throws {
    let copy = copies[lang]!
    let timeline = Timeline(copy: copy, durations: durations)
    var shots: [String: NSImage] = [:]
    for name in ["ask", "history"] { shots[name] = NSImage(contentsOfFile: "\(shotsDir)/\(lang)/\(name).png") }
    let appIcon = NSImage(contentsOfFile: iconPath)!

    // План звука: фразы, «вжух» на переходах, щелчки мыши.
    var plan: [String] = []
    for (i, p) in timeline.phrases.enumerated() { plan.append("voice \(i) \(Int(p.start * 1000))") }
    for s in timeline.sceneStarts.dropFirst() { plan.append("whoosh \(Int((s - 0.2) * 1000))") }
    let renameDone = timeline.sceneStarts[1] + timeline.localPhraseStart(scene: 1, index: 1)
    let clicks = [timeline.sceneStarts[1] + 0.55, renameDone - 0.3,
                  timeline.sceneStarts[4] + max(2.0, timeline.sceneDurations[4] - 1.6),
                  timeline.sceneStarts[5] + max(1.5, timeline.sceneDurations[5] - 1.5)]
    for c in clicks { plan.append("click \(Int(c * 1000))") }
    plan.append("total \(Int(timeline.total * 1000))")
    try plan.joined(separator: "\n").write(to: output.appendingPathExtension("plan"), atomically: true, encoding: .utf8)

    try? FileManager.default.removeItem(at: output)
    let writer = try AVAssetWriter(outputURL: output, fileType: .mp4)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: Int(W), AVVideoHeightKey: Int(H),
        AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 10_000_000, AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel],
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
        let renderer = ImageRenderer(content: Frame(t: t, timeline: timeline, copy: copy, shots: shots, appIcon: appIcon))
        renderer.scale = 1
        guard let image = renderer.cgImage else { continue }
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
        // Приводим к 48 кГц стерео.
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
        case "render":
            let durations = try JSONDecoder().decode([Double].self, from: Data(contentsOf: URL(fileURLWithPath: a[4])))
            _ = NSApplication.shared
            try await render(lang: a[2], shotsDir: a[3], durations: durations, output: URL(fileURLWithPath: a[5]), iconPath: a[6])
        case "mix":
            try mix(plan: a[2], voiceDir: a[3], whoosh: a[4], click: a[5], output: a[6])
        default:
            print("usage: promo lines <lang> | promo render <lang> <shots> <durations.json> <out.mp4> <icon.png>")
        }
    }
}
