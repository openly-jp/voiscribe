import Foundation
enum Language: String{
    case ja = "ja"
    case en = "en"
}
class RecognizedSpeech {
    var title: String
    var audioFileURL: URL
    var language: Language
    var transcriptionLines: [TranscriptionLine]
    var createdAt: Date
    var updatedAt: Date
    
    init(audioFileURL: URL, language: Language, transcriptionLines: [TranscriptionLine]) {
        self.title = "タイトル未定"
        self.audioFileURL = audioFileURL
        self.language = language
        self.transcriptionLines = transcriptionLines
        // NOTE: This is a UNIX Time
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
