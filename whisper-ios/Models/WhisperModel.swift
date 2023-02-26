import Foundation

enum Size: String, CaseIterable, Identifiable {
    case base
    case small
    case medium

    init() {
        self = .small
    }

    // just for ForEach operation
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .base:
            return "Base"
        case .small:
            return "Small"
        case .medium:
            return "Medium"
        }
    }

    var speed: Int {
        switch self {
        case .base:
            return 3
        case .small:
            return 2
        case .medium:
            return 1
        }
    }

    var accuracy: Int {
        switch self {
        case .base:
            return 1
        case .small:
            return 2
        case .medium:
            return 3
        }
    }

    var megabytes: Double {
        switch self {
        case .base:
            return 148
        case .small:
            return 488
        case .medium:
            return 1530
        }
    }
}

enum Lang: String, Identifiable, CaseIterable {
    case ja
    case en
    case multi

    // just for ForEach operation
    var id: String { rawValue }

    init() {
        self = .multi
    }
}

let userDefaultWhisperModelDownloadPrefix = "user-default-whisper-model-download" // "-" + size + "-" + lang
let userDefaultWhisperModelDownloadingPrefix = "user-default-whisper-model-downloading" // "-" + size + "-" + lang

class WhisperModel: Identifiable, ObservableObject {
    var localPath: URL?
    var size: Size
    var language: Lang
    var whisperContext: OpaquePointer?

    var isDownloaded: Bool

    init(size: Size, language: Lang) {
        self.size = size
        self.language = language

        let isDownloadedKey = "\(userDefaultWhisperModelDownloadPrefix)-\(self.size.rawValue)-\(self.language.rawValue)"
        if UserDefaults.standard.object(forKey: isDownloadedKey) == nil {
            let isModelExists = WhisperModelRepository.modelExists(
                size: size,
                language: language
            )
            UserDefaults.standard.set(isModelExists, forKey: isDownloadedKey)
        }
        isDownloaded = UserDefaults.standard.object(forKey: isDownloadedKey) as! Bool

        if isDownloaded {
            if WhisperModelRepository.isModelBundled(size: size, language: language) {
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
        let key = "\(userDefaultWhisperModelDownloadPrefix)-\(self.size.rawValue)-\(self.language.rawValue)"
        if UserDefaults.standard.object(forKey: key) == nil {
            let isModelExists = WhisperModelRepository.modelExists(
                size: size,
                language: language
            )
            UserDefaults.standard.set(isModelExists, forKey: key)
        }
        isDownloaded = UserDefaults.standard.object(forKey: key) as! Bool
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
                DispatchQueue.main.async {
                    self.isDownloaded = true
                    let key = "\(userDefaultWhisperModelDownloadPrefix)-\(self.size.rawValue)-\(self.language.rawValue)"
                    UserDefaults.standard.set(true, forKey: key)
                }
            case let .failure(error):
                self.isDownloaded = false
                err = NSError(
                    domain: "Failed to download model: \(error.localizedDescription)",
                    code: -1
                )
            }

            completeCallback(err)
        }
    }

    func loadModel(callback: @escaping (Error?) -> Void) {
        Logger.debug("Loading Model: model size \(size), model language \(language.rawValue), model name \(name)")
        guard let modelUrl = localPath else {
            Logger.error("Failed to parse model url")
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.whisperContext = whisper_init_from_file(modelUrl.path)

            var err: Error?
            if self.whisperContext == nil {
                err = NSError(domain: "Failed to load model", code: -1)
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
            throw NSError(domain: "failed to delete model", code: -1)
        }
    }

    // prefer this fucntion to deinit cause
    // we can avoid two models are loaded simultaneouly
    // (for a short amout of time)
    func freeModel() {
        whisper_free(whisperContext)
    }
}
