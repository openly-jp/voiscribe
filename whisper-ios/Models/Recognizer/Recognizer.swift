import Foundation

protocol Recognizer: ObservableObject {
    func streamingRecognize(
        audioFileURL: URL,
        language: RecognitionLanguage,
        recognizingSpeech: RecognizedSpeech,
        feasibilityCheck: @escaping (RecognizedSpeech) -> Bool
    )
}
