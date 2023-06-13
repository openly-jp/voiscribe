import Foundation

protocol Recognizer: ObservableObject {
    func streamingRecognize(
        audioFileURL: URL,
        language: Language,
        recognizingSpeech: RecognizedSpeech,
        feasibilityCheck: @escaping (RecognizedSpeech) -> Bool
    )
}
