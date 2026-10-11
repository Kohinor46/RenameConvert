// Группы параметров конвертации — общие для вкладки «Параметры» и окна-вопроса.

import SwiftUI

struct ParamsSections: View {
    @Binding var params: ConversionParams
    var sections: [ParamSection] = ParamSection.allCases

    var body: some View {
        ForEach(sections, id: \.self) { section in
            switch section {
            case .image: imageSection
            case .video: videoSection
            case .gif: gifSection
            case .audio: audioSection
            case .document: documentSection
            }
        }
    }

    private var imageSection: some View {
        Section("Картинки") {
            LabeledContent("Качество JPEG, HEIC, AVIF, WebP") {
                HStack {
                    Slider(value: $params.imageQuality, in: 0.5...1, step: 0.05)
                        .frame(width: 160)
                    Text("\(Int((params.imageQuality * 100).rounded()))%")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }

    private var videoSection: some View {
        Section("Видео") {
            Picker("Кодек", selection: $params.videoCodec) {
                ForEach(VideoCodec.allCases) { Text($0.title).tag($0) }
            }
            Picker("Разрешение", selection: $params.videoResolution) {
                ForEach(VideoResolution.allCases) { Text($0.title).tag($0) }
            }
            Picker("Частота кадров", selection: $params.videoFPS) {
                ForEach(ConversionParams.fpsOptions, id: \.self) { Text($0 == 0 ? "Исходная" : "\($0) кадр/с").tag($0) }
            }
            Toggle("Удалять геопозицию и личные метаданные", isOn: $params.stripMetadata)
        }
    }

    private var gifSection: some View {
        Section("GIF из видео") {
            Picker("Частота кадров", selection: $params.gifFPS) {
                ForEach(ConversionParams.gifFPSOptions, id: \.self) { Text("\($0) кадр/с").tag($0) }
            }
            Picker("Ширина", selection: $params.gifMaxWidth) {
                ForEach(ConversionParams.gifWidthOptions, id: \.self) { Text($0 == 0 ? "Исходная" : "\($0) px").tag($0) }
            }
        }
    }

    private var audioSection: some View {
        Section("Аудио (AAC, MP3)") {
            Picker("Битрейт", selection: $params.audioBitrate) {
                ForEach(ConversionParams.bitrateOptions, id: \.self) { Text("\($0) кбит/с").tag($0) }
            }
        }
    }

    private var documentSection: some View {
        Section("Документы → PDF") {
            Picker("Размер страницы", selection: $params.pdfPageSize) {
                ForEach(PageSize.allCases) { Text($0.title).tag($0) }
            }
        }
    }
}
