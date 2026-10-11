// Картинки: ImageIO; PDF → картинка: CoreGraphics.

import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ImageEngine {
    /// Форматы, где можно сохранить несколько кадров/страниц.
    private static let multiFrameTypeIDs: Set<String> = ["com.compuserve.gif", "public.tiff", "public.heics", "com.adobe.pdf"]

    /// Форматы со сжатием с потерями — для них задаём качество.
    private static let lossyTypeIDs: Set<String> = ["public.jpeg", "public.heic", "public.avif", "public.jpeg-2000"]

    /// Настоящий формат картинки по содержимому (не по расширению).
    static func actualTypeID(of url: URL) -> String? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil), CGImageSourceGetCount(src) > 0 else { return nil }
        return CGImageSourceGetType(src) as String?
    }

    static func convert(_ input: URL, to output: URL, type: UTType, quality: Double) throws {
        guard let src = CGImageSourceCreateWithURL(input as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              CGImageSourceGetCount(src) > 0 else { throw ConvertError.unreadable }

        let frames = multiFrameTypeIDs.contains(type.identifier) ? CGImageSourceGetCount(src) : 1
        guard let dst = CGImageDestinationCreateWithURL(output as CFURL, type.identifier as CFString, frames, nil) else {
            throw ConvertError.encodeFailed
        }
        let options = encodeOptions(type: type, quality: quality)

        for i in 0..<frames {
            if type == .jpeg, let img = CGImageSourceCreateImageAtIndex(src, i, nil), hasAlpha(img),
               let flat = flattenOnWhite(img) {
                // JPEG не умеет прозрачность — иначе фон станет чёрным.
                var props = (CGImageSourceCopyPropertiesAtIndex(src, i, nil) as? [CFString: Any]) ?? [:]
                props.merge(options) { _, new in new }
                CGImageDestinationAddImage(dst, flat, props as CFDictionary)
            } else {
                // Копирует картинку вместе с метаданными (EXIF, ориентация, цветовой профиль).
                CGImageDestinationAddImageFromSource(dst, src, i, options as CFDictionary)
            }
        }
        guard CGImageDestinationFinalize(dst) else { throw ConvertError.encodeFailed }
    }

    /// Записывает одиночный кадр (из видео или PDF).
    static func write(_ image: CGImage, to output: URL, type: UTType, quality: Double) throws {
        guard let dst = CGImageDestinationCreateWithURL(output as CFURL, type.identifier as CFString, 1, nil) else {
            throw ConvertError.encodeFailed
        }
        let img = (type == .jpeg && hasAlpha(image)) ? (flattenOnWhite(image) ?? image) : image
        CGImageDestinationAddImage(dst, img, encodeOptions(type: type, quality: quality) as CFDictionary)
        guard CGImageDestinationFinalize(dst) else { throw ConvertError.encodeFailed }
    }

    /// Первая страница PDF в картинку (144 dpi, белый фон).
    static func renderPDFPage(_ input: URL, to output: URL, type: UTType, quality: Double) throws {
        guard let doc = CGPDFDocument(input as CFURL), let page = doc.page(at: 1) else { throw ConvertError.unreadable }
        let box = page.getBoxRect(.cropBox)
        let scale: CGFloat = 2
        let rotated = page.rotationAngle % 180 != 0
        let pageRect = CGRect(x: 0, y: 0, width: rotated ? box.height : box.width, height: rotated ? box.width : box.height)
        let w = Int(pageRect.width * scale), h = Int(pageRect.height * scale)
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { throw ConvertError.encodeFailed }
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        // getDrawingTransform не увеличивает, поэтому масштаб задаём отдельно, а поворот — в размере страницы.
        ctx.scaleBy(x: scale, y: scale)
        ctx.concatenate(page.getDrawingTransform(.cropBox, rect: pageRect, rotate: 0, preserveAspectRatio: true))
        ctx.drawPDFPage(page)
        guard let img = ctx.makeImage() else { throw ConvertError.encodeFailed }
        try write(img, to: output, type: type, quality: quality)
    }

    private static func encodeOptions(type: UTType, quality: Double) -> [CFString: Any] {
        lossyTypeIDs.contains(type.identifier) ? [kCGImageDestinationLossyCompressionQuality: quality] : [:]
    }

    static func hasAlpha(_ img: CGImage) -> Bool {
        switch img.alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast: return false
        default: return true
        }
    }

    static func flattenOnWhite(_ img: CGImage) -> CGImage? {
        let space = img.colorSpace.flatMap { $0.model == .rgb ? $0 : nil } ?? CGColorSpace(name: CGColorSpace.sRGB)!
        guard let ctx = CGContext(data: nil, width: img.width, height: img.height, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
        let rect = CGRect(x: 0, y: 0, width: img.width, height: img.height)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fill(rect)
        ctx.draw(img, in: rect)
        return ctx.makeImage()
    }
}
