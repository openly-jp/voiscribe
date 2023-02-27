import FirebaseCrashlytics
import Foundation

enum Size: String {
    case tiny
    case base
    case small
    case medium

    init() {
        self = .tiny
    }
}

enum Lang: String {
    case ja
    case en
    case multi

    init() {
        self = .en
    }
}

class WhisperModel: Identifiable, ObservableObject {
    var localPath: URL?
    var size: Size
    var language: Lang
    var whisperContext: OpaquePointer?
    @Published var isDownloaded: Bool

    init(size: Size, language: Lang) {
        self.size = size
        self.language = language

        isDownloaded = WhisperModelRepository.modelExists(size: size, language: language)
        if isDownloaded {
            if size == .tiny {
                let urlStr = Bundle.main.path(
                    forResource: "ggml-\(size.rawValue).\(language.rawValue)",
                    ofType: "bin"
                )
                localPath = URL(string: urlStr!)!
            } else {
                localPath = getURLByName(fileName: "ggml-\(size.rawValue).\(language.rawValue).bin")
            }
        }
    }

    init(
        localPath: URL?,
        size: Size,
        language: Lang
    ) {
        self.localPath = localPath
        self.size = size
        self.language = language
        isDownloaded = true
    }

    var name: String {
        "\(size.rawValue)-\(language.rawValue)"
    }

    func downloadModel(
        completeCallback: @escaping (Error?) -> Void,
        updateCallback: @escaping (Float) -> Void
    ) {
        assert(!isDownloaded)
        WhisperModelRepository.fetchWhisperModel(
            size: size,
            language: language,
            update: updateCallback
        ) { result in
            var err: Error?

            switch result {
            case let .success(modelURL):
                self.localPath = modelURL
                DispatchQueue.main.async { self.isDownloaded = true }
            case let .failure(error):
                self.isDownloaded = false
                err = NSError(
                    domain: "Failed to download model: \(error.localizedDescription)",
                    code: -1
                )
                Crashlytics.crashlytics().record(error: err!)
            }

            completeCallback(err)
        }
    }

    func loadModel(callback: @escaping (Error?) -> Void) {
        Logger.debug("Loading Model: model size \(size), model language \(language.rawValue), model name \(name)")
        guard let modelUrl = localPath else {
            Crashlytics.crashlytics().log("Failed to parse model url")
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.whisperContext = whisper_init_from_file(modelUrl.path)

            var err: Error?
            if self.whisperContext == nil {
                err = NSError(domain: "Failed to load model", code: -1)
                Crashlytics.crashlytics().record(error: err!)
            }

            callback(err)
        }
    }

    func deleteModel() throws {
        let flag = WhisperModelRepository.deleteWhisperModel(
            size: size,
            language: language
        )
        isDownloaded = false
        if !flag {
            let err = NSError(domain: "failed to delete model", code: -1)
            Crashlytics.crashlytics().record(error: err)
            throw err
        }
    }

    // prefer this fucntion to deinit cause
    // we can avoid two models are loaded simultaneouly
    // (for a short amout of time)
    func freeModel() {
        whisper_free(whisperContext)
    }
}
