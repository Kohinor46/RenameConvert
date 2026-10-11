// Документы: NSAttributedString (txt, rtf, html, docx, doc, odt), PDF через PDFKit/CoreText.

import AppKit
import PDFKit

enum DocumentEngine {
    private static let documentTypes: [String: NSAttributedString.DocumentType] = [
        "txt": .plain, "text": .plain, "rtf": .rtf, "html": .html, "htm": .html,
        "docx": .officeOpenXML, "doc": .docFormat, "odt": .openDocument, "webarchive": .webArchive,
    ]

    static func convert(_ input: URL, from: String, to output: URL, ext: String, pageSize: CGSize) async throws {
        // HTML и веб-архивы разбирает WebKit — только в главном потоке; остальное не держит интерфейс.
        if documentTypes[from] == .html || documentTypes[from] == .webArchive {
            try await MainActor.run {
                try write(try read(input, ext: from), to: output, ext: ext, pageSize: pageSize)
            }
        } else {
            try write(try read(input, ext: from), to: output, ext: ext, pageSize: pageSize)
        }
    }

    private static func read(_ url: URL, ext: String) throws -> NSAttributedString {
        if ext == "pdf" {
            guard let pdf = PDFDocument(url: url) else { throw ConvertError.unreadable }
            let result = NSMutableAttributedString()
            for i in 0..<pdf.pageCount {
                guard let page = pdf.page(at: i)?.attributedString else { continue }
                result.append(page)
                result.append(NSAttributedString(string: "\n"))
            }
            return result
        }
        guard let type = documentTypes[ext] else { throw ConvertError.unsupported }
        var data = try Data(contentsOf: url)
        var options: [NSAttributedString.DocumentReadingOptionKey: Any] = [.documentType: type]
        if type == .plain {
            // Кодировку текста определяем сами (UTF-8, UTF-16 с BOM, CP1251…) и отдаём дальше уже в UTF-8.
            data = Data(try decodeText(data).utf8)
            options[.characterEncoding] = String.Encoding.utf8.rawValue
        } else if type == .html, !declaresCharset(data) {
            // Без явной кодировки HTML без <meta charset> читается как Latin-1/CP1251.
            options[.characterEncoding] = String.Encoding.utf8.rawValue
        }
        return try NSAttributedString(data: data, options: options, documentAttributes: nil)
    }

    private static func decodeText(_ data: Data) throws -> String {
        if let text = String(data: data, encoding: .utf8) { return text }
        var converted: NSString?
        let encoding = NSString.stringEncoding(for: data, encodingOptions: [
            .suggestedEncodingsKey: [String.Encoding.windowsCP1251.rawValue, String.Encoding.utf16.rawValue],
            .allowLossyKey: false,
        ], convertedString: &converted, usedLossyConversion: nil)
        guard encoding != 0, let converted else { throw ConvertError.unreadable }
        return converted as String
    }

    /// Указана ли кодировка в самом HTML (`<meta charset=…>` или `content="…; charset=…"`).
    private static func declaresCharset(_ data: Data) -> Bool {
        String(decoding: data.prefix(4096), as: UTF8.self).lowercased().contains("charset=")
    }

    private static func write(_ text: NSAttributedString, to url: URL, ext: String, pageSize: CGSize) throws {
        if ext == "pdf" {
            try renderPDF(text, to: url, pageSize: pageSize)
            return
        }
        guard let type = documentTypes[ext] else { throw ConvertError.unsupported }
        if type == .plain {
            try Data(text.string.utf8).write(to: url)
            return
        }
        let data = try text.data(from: NSRange(location: 0, length: text.length), documentAttributes: [.documentType: type])
        try data.write(to: url)
    }

    /// Вёрстка текста по страницам через CoreText.
    private static func renderPDF(_ text: NSAttributedString, to url: URL, pageSize: CGSize) throws {
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let ctx = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else { throw ConvertError.encodeFailed }
        let framesetter = CTFramesetterCreateWithAttributedString(text)
        let textRect = mediaBox.insetBy(dx: 56, dy: 56)
        var start = 0
        repeat {
            ctx.beginPDFPage(nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: start, length: 0),
                                                 CGPath(rect: textRect, transform: nil), nil)
            CTFrameDraw(frame, ctx)
            ctx.endPDFPage()
            let visible = CTFrameGetVisibleStringRange(frame)
            if visible.length == 0 { break }
            start += visible.length
        } while start < text.length
        ctx.closePDF()
    }
}
