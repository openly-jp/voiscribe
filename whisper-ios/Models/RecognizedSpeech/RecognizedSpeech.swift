import Foundation

let userDefaultRecognitionLanguageKey = "user-default-recognition-language"

enum Language: String, CaseIterable, Identifiable {
    case ja
    case en

    init() {
        guard let deviceLanguageCode = Locale(identifier: Locale.preferredLanguages.first!).languageCode else {
            self = .en
            return
        }

        if deviceLanguageCode == "ja" {
            self = .ja
        } else {
            self = .en
        }
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

    var tmpAudioData: [Float32] = []
    var promptTokens: [Int32] = []
    var remainingAudioData: [Float32] = []

    /// this is used in streaming recognition
    init(audioFileURL: URL, language: Language) {
        id = UUID()
        title = NSLocalizedString("未定", comment: "")
        self.audioFileURL = audioFileURL
        self.language = language
        transcriptionLines = []
        createdAt = Date()
        updatedAt = Date()
    }
    
    init(language: Language) {
        id = UUID()
        title = NSLocalizedString("未定", comment: "")
        // create initial URL
        let paths = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
        )
        let docsDirect = paths[0]
        audioFileURL = docsDirect.appendingPathComponent("\(id.uuidString).m4a")
        self.language = language
        transcriptionLines = []
        createdAt = Date()
        updatedAt = Date()
    }

    init(audioFileURL: URL, language: Language, transcriptionLines: [TranscriptionLine]) {
        id = UUID()
        title = NSLocalizedString("未定", comment: "")
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
