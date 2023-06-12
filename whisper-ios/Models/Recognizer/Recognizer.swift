import Foundation

protocol Recognizer: ObservableObject {
    func streamingRecognize(
        audioFileURL: URL,
        language: Language,
        recognizingSpeech: RecognizedSpeech,
        isPromptingActive: Bool,
        isRemainingAudioConcatActive: Bool,
        feasibilityCheck: @escaping (RecognizedSpeech) -> Bool
    )
}
