import Foundation

class RecognitionManager: ObservableObject {
    // @Published of `model` and `currentRecognitionLanguage` is neccessary to trigger rendering
    // when user change a model or recognition language
    @Published private var model: WhisperModel

    @Published var currentRecognitionLanguage: RecognitionLanguage {
        didSet {
            CustomUserDefaults.set_(
                key: USER_DEFAULT_RECOGNITION_LANGUAGE_KEY,
                value: currentRecognitionLanguage
            )
        }
    }

    var currentModelSize: Size { model.size }

    // TODO: use Reocgnizer protocol instead of concrete type class
    @Published private var recognizerDict = [UUID: WhisperRecognizer]()

    let recognitionQueue = DispatchQueue(label: RECOGNITION_DISPATCH_QUEUE_NAME)

    var isRecognizing: Bool {
        recognizerDict.values.reduce(false) { $0 || $1.state == .recognizing }
    }

    init(modelLoadCallback: @escaping () -> Void) {
        let defaultRecognitionLanguage = CustomUserDefaults.get_(
            key: USER_DEFAULT_RECOGNITION_LANGUAGE_KEY,
            defaultValue: RecognitionLanguage()
        )
        currentRecognitionLanguage = defaultRecognitionLanguage
        model = WhisperModel(recognitionLanguage: defaultRecognitionLanguage)

        recognitionQueue.async {
            try! self.model.loadModel { err in
                if let err { Logger.error(err); return }
                modelLoadCallback()
            }
        }
    }

    /// Change model to another model specified in arguments and load the model
    ///
    /// This function can be called while recognizing
    /// because loading of the model is appended to the queue for recognition tasks
    func changeModel(
        newModel: WhisperModel,
        recognitionLanguage: RecognitionLanguage,
        callback: @escaping (Error?) -> Void
    ) {
        currentRecognitionLanguage = recognitionLanguage
        if model.equalsTo(newModel) {
            callback(nil)
            return
        }

        CustomUserDefaults.set_(key: USER_DEFAULT_MODEL_SIZE_KEY, value: newModel.size)

        // changing model reference must be executed on the fly
        // to update the view of which model is loaded
        model = newModel
        recognitionQueue.async {
            self.model.freeModel()
            try! newModel.loadModel { err in callback(err) }
        }
    }

    func startRecognition() -> RecognizedSpeech {
        let recognizingSpeech = RecognizedSpeech(language: currentRecognitionLanguage)
        recognizerDict[recognizingSpeech.id] = try! WhisperRecognizer(
            whisperModel: model,
            recognitionLanguage: currentRecognitionLanguage,
            recognitionQueue: recognitionQueue
        )
        return recognizingSpeech
    }

    func streamingRecognize(
        audioFileURL: URL,
        recognizingSpeech: RecognizedSpeech
    ) {
        guard let recognizer = recognizerDict[recognizingSpeech.id] else {
            Logger.error("you have to first start recognition.")
            return
        }

        recognizer.streamingRecognize(
            audioFileURL: audioFileURL,
            recognizingSpeech: recognizingSpeech
        )
    }

    func completeRecognition(recognizingSpeech: RecognizedSpeech) {
        guard let recognizer = recognizerDict[recognizingSpeech.id] else {
            Logger.error("you have to first start recognition.")
            return
        }

        recognizer.completeRecognition {
            DispatchQueue.main.async { self.recognizerDict[recognizingSpeech.id] = nil }
        }
    }

    func abortRecognition(
        recognizingSpeech: RecognizedSpeech,
        cleanUp: @escaping () -> Void = {}
    ) {
        guard let recognizer = recognizerDict[recognizingSpeech.id] else {
            Logger.error("you have to first start recognition.")
            return
        }

        recognizer.abortRecognition {
            cleanUp()
            DispatchQueue.main.async { self.recognizerDict[recognizingSpeech.id] = nil }
        }
    }

    func isRecognizing(_ recognizedSpeechId: UUID) -> Bool {
        guard let recognizer = recognizerDict[recognizedSpeechId] else {
            return false
        }

        return recognizer.state == .recognizing
    }

    func getRecognizer(_ recognizedSpeechId: UUID) -> WhisperRecognizer {
        recognizerDict[recognizedSpeechId]!
    }

    func isModelSelected(_ selectedModel: WhisperModel) -> Bool {
        model.equalsTo(selectedModel)
    }
}

class CustomUserDefaults {
    init() {}

    static func get_<T: Codable>(key: String, defaultValue: T) -> T {
        let data = UserDefaults.standard.object(forKey: key) as? Data
        guard let data else { return defaultValue }
        return try! JSONDecoder().decode(T.self, from: data)
    }

    static func set_(key: String, value: some Codable) {
        if let encoded = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
