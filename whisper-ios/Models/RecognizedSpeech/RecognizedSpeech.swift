import Foundation

let userDefaultRecognitionLanguageKey = "user-default-recognition-language"

enum Language: String, CaseIterable, Identifiable {
    case ja
    case en
    
    init() {
        self = .ja
    }
    
    // just for ForEach operation
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ja:
            return "日本語"
        case .en:
            return "英語"
        }
    }
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
    var promptTokens: [Int32] = []
    var remainingAudioData: [Float32] = []

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
