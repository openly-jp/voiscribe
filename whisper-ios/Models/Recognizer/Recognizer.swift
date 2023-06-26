import Foundation

protocol Recognizer: ObservableObject {
    func streamingRecognize(
        audioFileURL: URL,
        recognizingSpeech: RecognizedSpeech
    )
}
