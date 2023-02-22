import Foundation

protocol Recognizer: ObservableObject {
    func recognize(
        audioFileURL: URL,
        language: Language,
        callback: @escaping (RecognizedSpeech) -> Void
    ) throws -> RecognizedSpeech
}
