import Foundation

enum Language: String, CaseIterable {
    case ja
    case en
}

class RecognizedSpeech: Identifiable {
    let id: UUID
    var title: String
    var audioFileURL: URL
    var language: Language
    var transcriptionLines: [TranscriptionLine]
    var createdAt: Date
    var updatedAt: Date

    var tmpAudioDataList: [[Float32]] = []

    /// this is used in streaming recognition
    init(audioFileURL: URL, language: Language) {
        id = UUID()
        title = "未定"
        self.audioFileURL = audioFileURL
        self.language = language
        transcriptionLines = []
        createdAt = Date()
        updatedAt = Date()
    }

    init(audioFileURL: URL, language: Language, transcriptionLines: [TranscriptionLine]) {
        id = UUID()
        title = "未定"
        self.audioFileURL = audioFileURL
        self.language = language
        self.transcriptionLines = transcriptionLines
        // NOTE: This is a UNIX Time
        createdAt = Date()
        updatedAt = Date()
    }

    init(
        id: UUID,
        title: String,
        audioFileURL: URL,
        language: Language,
        transcriptionLines: [TranscriptionLine],
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.audioFileURL = audioFileURL
        self.language = language
        self.transcriptionLines = transcriptionLines
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
