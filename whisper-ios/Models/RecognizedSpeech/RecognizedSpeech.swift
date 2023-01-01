import Foundation

enum Language: String{
    case ja = "ja"
    case en = "en"
}
class RecognizedSpeech: Identifiable {
    let id: UUID
    var title: String
    var audioFileURL: URL
    var language: Language
    var transcriptionLines: [TranscriptionLine]
    var createdAt: Date
    var updatedAt: Date

    init(audioFileURL: URL, language: Language, transcriptionLines: [TranscriptionLine]) {
        self.id = UUID()
        self.title = "未定"
        self.audioFileURL = audioFileURL
        self.language = language
        self.transcriptionLines = transcriptionLines
        // NOTE: This is a UNIX Time
        self.createdAt = Date()
        self.updatedAt = Date()
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
