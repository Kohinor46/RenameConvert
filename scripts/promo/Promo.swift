// Рендер промо-ролика для Instagram Reels (1080×1920, 30 кадр/с) без звука.
// Использование: promo <ru|en> <папка со скриншотами> <durations.json> <out.mp4> <AppIcon.png>
//                promo lines <ru|en>
// durations.json — длительности сцен в секундах (по длине озвучки).

import AppKit
import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

let W: CGFloat = 1080, H: CGFloat = 1920, FPS = 30

// MARK: - Тексты

struct Copy {
    let lines: [String]          // озвучка = субтитры, по сцене
    let hook: String
    let hookSub: String
    let categories: [(String, String, String)]   // символ, название, пример
    let features: [(String, String)]
    let ctaSub: String
    let ffmpegTitle: String
}

let copies: [String: Copy] = [
    "ru": Copy(
        lines: [
            "Хватит искать конвертеры.",
            "RenameConvert меняет формат файла, когда вы просто меняете расширение в Finder.",
            "Картинки, видео, звук, документы, данные и архивы.",
            "Видео в MP4 или GIF, звук из видео в MP3, документ Word в PDF.",
            "Встроенный FFmpeg понимает даже WebP, MKV, AVI и OGG.",
            "Правила решают, что делать: спросить, конвертировать сразу или пропустить.",
            "Перед конвертацией можно выбрать кодек, разрешение и частоту кадров.",
            "Оригинал уходит в Корзину, а из истории его можно вернуть одним нажатием.",
            "Всё работает локально, на двадцати трёх языках, и обновляется само.",
            "RenameConvert. Скачайте на GitHub.",
        ],
        hook: "Переименуй —\nи файл\nсконвертирован",
        hookSub: "RenameConvert для macOS",
        categories: [("photo", "Картинки", "heic → jpg"), ("film", "Видео", "mov → mp4"),
                     ("waveform", "Аудио", "wav → mp3"), ("doc.text", "Документы", "docx → pdf"),
                     ("curlybraces", "Данные", "json → plist"), ("archivebox", "Архивы", "zip → 7z")],
        features: [("lock.fill", "Локально — файлы никуда не уходят"), ("globe", "23 языка"),
                   ("arrow.down.circle.fill", "Обновляется само")],
        ctaSub: "macOS 15+ · Apple Silicon и Intel",
        ffmpegTitle: "Встроенный FFmpeg"),
    "en": Copy(
        lines: [
            "Stop hunting for file converters.",
            "RenameConvert changes a file's format when you simply change its extension in Finder.",
            "Images, video, audio, documents, data, and archives.",
            "Video to MP4 or GIF, audio from video to MP3, a Word document to PDF.",
            "The built-in FFmpeg even handles WebP, MKV, AVI, and OGG.",
            "Rules decide what happens: ask first, convert right away, or skip.",
            "Before converting, pick the codec, resolution, and frame rate.",
            "The original goes to the Trash, and you can restore it from History in one click.",
            "Everything runs locally, in twenty-three languages, and updates itself.",
            "RenameConvert. Get it on GitHub.",
        ],
        hook: "Rename it.\nIt's\nconverted.",
        hookSub: "RenameConvert for macOS",
        categories: [("photo", "Images", "heic → jpg"), ("film", "Video", "mov → mp4"),
                     ("waveform", "Audio", "wav → mp3"), ("doc.text", "Documents", "docx → pdf"),
                     ("curlybraces", "Data", "json → plist"), ("archivebox", "Archives", "zip → 7z")],
        features: [("lock.fill", "Local — files never leave your Mac"), ("globe", "23 languages"),
                   ("arrow.down.circle.fill", "Updates itself")],
        ctaSub: "macOS 15+ · Apple Silicon & Intel",
        ffmpegTitle: "Built-in FFmpeg"),
]

// MARK: - Вспомогательное

func ease(_ x: Double) -> Double { let c = min(max(x, 0), 1); return 1 - pow(1 - c, 3) }
func spring(_ x: Double) -> Double {
    let c = min(max(x, 0), 1)
    return 1 - exp(-6 * c) * cos(10 * c) * (1 - c * 0.2)
}
func appear(_ t: Double, at start: Double, length: Double = 0.45) -> Double { ease((t - start) / length) }

let accent = Color(red: 0.45, green: 0.36, blue: 1.0)
func icon(_ ext: String, size: CGFloat = 1024) -> NSImage {
    let img = NSWorkspace.shared.icon(for: UTType(filenameExtension: ext) ?? .data)
    img.size = NSSize(width: size, height: size)
    return img
}

struct Background: View {
    let t: Double
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.07, green: 0.09, blue: 0.25), Color(red: 0.22, green: 0.10, blue: 0.48)],
                           startPoint: .top, endPoint: .bottom)
            Circle().fill(Color(red: 0.33, green: 0.62, blue: 1).opacity(0.35)).frame(width: 900).blur(radius: 160)
                .offset(x: -300 + 80 * sin(t / 3), y: -600 + 60 * cos(t / 4))
            Circle().fill(Color(red: 0.6, green: 0.3, blue: 1).opacity(0.35)).frame(width: 800).blur(radius: 160)
                .offset(x: 320 + 70 * cos(t / 3.5), y: 500 + 80 * sin(t / 5))
        }
    }
}

struct Caption: View {
    let text: String
    let progress: Double
    var body: some View {
        Text(text)
            .font(.system(size: 50, weight: .semibold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .padding(.horizontal, 44).padding(.vertical, 30)
            .background(RoundedRectangle(cornerRadius: 36).fill(.black.opacity(0.42)))
            .frame(maxWidth: 940)
            .opacity(ease(progress / 0.12))
    }
}

struct Card<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .background(RoundedRectangle(cornerRadius: 44).fill(.white))
            .shadow(color: .black.opacity(0.35), radius: 40, y: 20)
    }
}

/// Скриншот в рамке окна с лёгким наездом камеры.
struct Screenshot: View {
    let image: NSImage
    let t: Double, d: Double
    var width: CGFloat = 960
    var body: some View {
        let s = 0.96 + 0.06 * (t / d)
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ForEach([Color.red, .yellow, .green], id: \.self) { Circle().fill($0.opacity(0.85)).frame(width: 22) }
                Spacer()
            }
            .padding(.horizontal, 28).frame(height: 64).background(Color(white: 0.93))
            Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
        }
        .frame(width: width)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(color: .black.opacity(0.4), radius: 50, y: 24)
        .scaleEffect(s * (0.85 + 0.15 * spring(t / 0.7)))
        .opacity(appear(t, at: 0))
    }
}

// MARK: - Сцены

struct SceneView: View {
    let index: Int, t: Double, d: Double
    let copy: Copy
    let shots: [String: NSImage]
    let appIcon: NSImage

    var body: some View {
        ZStack {
            content.frame(width: W, height: 1350).offset(y: -170)
            VStack {
                Spacer()
                Caption(text: copy.lines[index], progress: t / d)
                    .padding(.bottom, 330)
            }
        }
        .frame(width: W, height: H)
        // Мягкая смена сцен.
        .opacity(min(ease(t / 0.25), ease((d - t) / 0.2)))
    }

    @ViewBuilder var content: some View {
        switch index {
        case 0: hook
        case 1: finderDemo
        case 2: categories
        case 3: conversions
        case 4: ffmpeg
        case 5: Screenshot(image: shots["rules"]!, t: t, d: d)
        case 6: Screenshot(image: shots["ask"]!, t: t, d: d, width: 760)
        case 7: Screenshot(image: shots["history"]!, t: t, d: d)
        case 8: features
        default: cta
        }
    }

    var hook: some View {
        VStack(spacing: 50) {
            Image(nsImage: appIcon).resizable().frame(width: 360, height: 360)
                .scaleEffect(0.6 + 0.4 * spring(t / 0.8))
                .rotationEffect(.degrees(-8 * (1 - ease(t / 0.8))))
            Text(copy.hook)
                .font(.system(size: 108, weight: .heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .opacity(appear(t, at: 0.25))
                .offset(y: 40 * (1 - appear(t, at: 0.25)))
            Text(copy.hookSub).font(.system(size: 44, weight: .medium)).foregroundStyle(.white.opacity(0.75))
                .opacity(appear(t, at: 0.6))
        }
    }

    /// Имитация переименования в Finder: photo.HEIC → photo.jpg.
    var finderDemo: some View {
        let typed = ["photo.HEIC", "photo.HEIC", "photo.", "photo.j", "photo.jp", "photo.jpg"]
        let step = min(typed.count - 1, max(0, Int((t - 0.6) / 0.3)))
        let name = typed[step]
        let selecting = t > 0.6 && step < 2
        let done = t > 0.6 + 0.3 * Double(typed.count) + 0.2
        let doneP = ease((t - (0.6 + 0.3 * Double(typed.count) + 0.2)) / 0.4)
        return Card {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    ForEach([Color.red, .yellow, .green], id: \.self) { Circle().fill($0.opacity(0.85)).frame(width: 22) }
                    Spacer()
                    Text("Finder").font(.system(size: 30, weight: .semibold)).foregroundStyle(.secondary)
                    Spacer().frame(width: 90)
                }
                .padding(.horizontal, 32).frame(height: 76).background(Color(white: 0.95))
                VStack(spacing: 34) {
                    ZStack(alignment: .bottomTrailing) {
                        Image(nsImage: icon(done ? "jpg" : "heic")).resizable().frame(width: 380, height: 380)
                        if done {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 110)).foregroundStyle(.white, .green)
                                .scaleEffect(spring(doneP)).offset(x: 20, y: 10)
                        }
                    }
                    HStack(spacing: 0) {
                        if selecting {
                            Text("photo.").foregroundStyle(.black)
                            Text("HEIC").foregroundStyle(.white).background(Color.accentColor.opacity(0.9))
                        } else {
                            Text(name).foregroundStyle(.black)
                            if !done && t > 0.6 { Rectangle().fill(.black).frame(width: 3, height: 52).opacity(sin(t * 12) > 0 ? 1 : 0) }
                        }
                    }
                    .font(.system(size: 54, weight: .medium))
                    .padding(.horizontal, 24).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10).stroke(t > 0.6 && !done ? Color.accentColor : .clear, lineWidth: 4))
                    Text("HEIC → JPG")
                        .font(.system(size: 46, weight: .bold)).foregroundStyle(.white)
                        .padding(.horizontal, 34).padding(.vertical, 14)
                        .background(Capsule().fill(.green))
                        .opacity(doneP).scaleEffect(0.8 + 0.2 * spring(doneP))
                }
                .padding(.vertical, 60)
            }
            .frame(width: 900)
        }
        .scaleEffect(0.9 + 0.1 * spring(t / 0.6))
    }

    var categories: some View {
        LazyVGrid(columns: [GridItem(.fixed(440), spacing: 36), GridItem(.fixed(440), spacing: 36)], spacing: 36) {
            ForEach(Array(copy.categories.enumerated()), id: \.offset) { i, item in
                let p = spring((t - 0.15 * Double(i)) / 0.6)
                VStack(alignment: .leading, spacing: 14) {
                    Image(systemName: item.0).font(.system(size: 64, weight: .semibold)).foregroundStyle(accent)
                    Text(item.1).font(.system(size: 50, weight: .bold)).foregroundStyle(.black)
                    Text(item.2).font(.system(size: 36, weight: .medium, design: .monospaced)).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(40)
                .background(RoundedRectangle(cornerRadius: 36).fill(.white))
                .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
                .scaleEffect(max(0.01, p)).opacity(min(1, max(0, p)))
            }
        }
    }

    var conversions: some View {
        let rows = [("clip", "mov", "mp4"), ("clip", "mov", "gif"), ("interview", "mkv", "mp3"), ("report", "docx", "pdf")]
        return VStack(spacing: 30) {
            ForEach(Array(rows.enumerated()), id: \.offset) { i, r in
                let start = 0.25 + 0.55 * Double(i)
                let p = ease((t - start) / 0.9)
                HStack(spacing: 18) {
                    VStack(spacing: 6) {
                        Image(nsImage: icon(r.1)).resizable().frame(width: 96, height: 96)
                        Text("\(r.0).\(r.1)").font(.system(size: 30, weight: .semibold)).foregroundStyle(.black).lineLimit(1)
                    }
                    .frame(width: 250)
                    Image(systemName: "arrow.right").font(.system(size: 44, weight: .bold)).foregroundStyle(accent)
                    VStack(spacing: 6) {
                        Image(nsImage: icon(r.2)).resizable().frame(width: 96, height: 96)
                        Text("\(r.0).\(r.2)").font(.system(size: 30, weight: .bold)).foregroundStyle(.black).lineLimit(1)
                    }
                    .frame(width: 250)
                    .opacity(p >= 1 ? 1 : 0.3)
                    Spacer(minLength: 0)
                    ZStack {
                        Circle().stroke(Color(white: 0.88), lineWidth: 10)
                        Circle().trim(from: 0, to: p).stroke(p >= 1 ? Color.green : accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        if p >= 1 { Image(systemName: "checkmark").font(.system(size: 40, weight: .heavy)).foregroundStyle(.green) }
                    }
                    .frame(width: 84, height: 84)
                }
                .padding(.horizontal, 36).padding(.vertical, 26)
                .frame(width: 960)
                .background(RoundedRectangle(cornerRadius: 34).fill(.white))
                .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
                .opacity(appear(t, at: start - 0.2, length: 0.3))
                .offset(x: 120 * (1 - appear(t, at: start - 0.2, length: 0.3)))
            }
        }
    }

    var ffmpeg: some View {
        let chips = ["WebP", "MP3", "MKV", "AVI", "WebM", "OGG", "OPUS", "FLV", "WMA", "MPEG-TS"]
        return VStack(spacing: 60) {
            Text(copy.ffmpegTitle).font(.system(size: 92, weight: .heavy)).foregroundStyle(.white)
                .scaleEffect(0.8 + 0.2 * spring(t / 0.6))
            FlowChips(chips: chips, t: t)
        }
    }

    var features: some View {
        VStack(alignment: .leading, spacing: 44) {
            ForEach(Array(copy.features.enumerated()), id: \.offset) { i, f in
                let p = appear(t, at: 0.2 + 0.5 * Double(i))
                HStack(spacing: 34) {
                    Image(systemName: f.0).font(.system(size: 76, weight: .semibold)).foregroundStyle(.white)
                        .frame(width: 140, height: 140).background(Circle().fill(accent))
                    Text(f.1).font(.system(size: 54, weight: .bold)).foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: 900, alignment: .leading)
                .opacity(p).offset(x: -80 * (1 - p))
            }
        }
    }

    var cta: some View {
        VStack(spacing: 44) {
            Image(nsImage: appIcon).resizable().frame(width: 400, height: 400)
                .scaleEffect(0.7 + 0.3 * spring(t / 0.8))
            Text("RenameConvert").font(.system(size: 104, weight: .heavy)).foregroundStyle(.white)
            HStack(spacing: 18) {
                Image(systemName: "arrow.down.circle.fill").font(.system(size: 52))
                Text("github.com/Kohinor46/RenameConvert").font(.system(size: 40, weight: .semibold))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 40).padding(.vertical, 24)
            .background(Capsule().fill(.white))
            .opacity(appear(t, at: 0.4))
            Text(copy.ctaSub).font(.system(size: 40, weight: .medium)).foregroundStyle(.white.opacity(0.8))
                .opacity(appear(t, at: 0.7))
        }
    }
}

struct FlowChips: View {
    let chips: [String]
    let t: Double
    var body: some View {
        VStack(spacing: 28) {
            ForEach(0..<(chips.count + 2) / 3, id: \.self) { row in
                HStack(spacing: 28) {
                    ForEach(row * 3..<min(chips.count, row * 3 + 3), id: \.self) { i in
                        let p = spring((t - 0.3 - 0.12 * Double(i)) / 0.5)
                        Text(chips[i]).font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 38).padding(.vertical, 22)
                            .background(Capsule().fill(.white))
                            .scaleEffect(max(0.01, p)).opacity(min(1, max(0, p)))
                    }
                }
            }
        }
    }
}

struct Frame: View {
    let scene: Int, t: Double, d: Double, global: Double
    let copy: Copy
    let shots: [String: NSImage]
    let appIcon: NSImage
    var body: some View {
        ZStack {
            Background(t: global)
            SceneView(index: scene, t: t, d: d, copy: copy, shots: shots, appIcon: appIcon)
        }
        .frame(width: W, height: H)
        .environment(\.colorScheme, .light)
    }
}

// MARK: - Запись

@MainActor
func render(lang: String, shotsDir: String, durations: [Double], output: URL, iconPath: String) async throws {
    let copy = copies[lang]!
    var shots: [String: NSImage] = [:]
    for name in ["rules", "ask", "history"] {
        shots[name] = NSImage(contentsOfFile: "\(shotsDir)/\(lang)/\(name).png")
    }
    let appIcon = NSImage(contentsOfFile: iconPath)!

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

    var frameIndex = 0
    for (scene, d) in durations.enumerated() {
        let frames = Int((d * Double(FPS)).rounded())
        for f in 0..<frames {
            let t = Double(f) / Double(FPS)
            let renderer = ImageRenderer(content: Frame(scene: scene, t: t, d: d, global: Double(frameIndex) / Double(FPS),
                                                        copy: copy, shots: shots, appIcon: appIcon))
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
            adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(frameIndex), timescale: CMTimeScale(FPS)))
            frameIndex += 1
        }
        print("scene \(scene) done (\(frames) frames)")
    }
    input.markAsFinished()
    await writer.finishWriting()
    if writer.status != .completed { throw writer.error! }
}

@main
struct Main {
    static func main() async throws {
        let a = CommandLine.arguments
        if a[1] == "lines" {   // promo lines <lang> — тексты озвучки, по строке на сцену
            print(copies[a[2]]!.lines.joined(separator: "\n"))
            return
        }
        let durations = try JSONDecoder().decode([Double].self, from: Data(contentsOf: URL(fileURLWithPath: a[3])))
        _ = NSApplication.shared
        try await render(lang: a[1], shotsDir: a[2], durations: durations, output: URL(fileURLWithPath: a[4]), iconPath: a[5])
    }
}
