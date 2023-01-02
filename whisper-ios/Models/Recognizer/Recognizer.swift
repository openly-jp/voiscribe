import Foundation

protocol Recognizer: ObservableObject {
    var is_ready: Bool { get }
    func recognize(
        audioFileURL: URL,
        language: Language,
        callback: @escaping (RecognizedSpeech) -> Void
    ) throws -> RecognizedSpeech
}
