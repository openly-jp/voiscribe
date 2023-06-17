import Foundation

let userDefaultRecognitionLanguageKey = "user-default-recognition-language"
let initialTitle = "未定"

enum RecognitionLanguage: String, Identifiable, CaseIterable {
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

    // SwiftUI `ForEach` needs elements to conform `Identifiable` protocol
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
    var language: RecognitionLanguage
    var transcriptionLines: [TranscriptionLine]
    var createdAt: Date
    var updatedAt: Date

    var tmpAudioData: [Float32] = []
    var promptTokens: [Int32] = []
    var remainingAudioData: [Float32] = []

    init(language: RecognitionLanguage) {
        id = UUID()
        title = NSLocalizedString(initialTitle, comment: "")
        // create initial Audio File URL
        audioFileURL = getAudioFileURL(id: id)
        self.language = language
        transcriptionLines = []
        createdAt = Date()
        updatedAt = Date()
    }

    init(audioFileURL: URL, language: RecognitionLanguage, transcriptionLines: [TranscriptionLine]) {
        id = UUID()
        title = NSLocalizedString(initialTitle, comment: "")
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
        language: RecognitionLanguage,
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
