import Foundation

enum Size: String, CaseIterable, Identifiable {
    case tiny
    case base
    case small
    case medium

    init() {
        self = .tiny
    }

    // just for ForEach operation
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tiny:
            return "Tiny"
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
        case .tiny:
            return 4
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
        case .tiny:
            return 1
        case .base:
            return 2
        case .small:
            return 3
        case .medium:
            return 4
        }
    }
    
    var gigabytes: Double {
        switch self {
        case .tiny:
            return 0.077
        case .base:
            return 0.148
        case .small:
            return 0.488
        case .medium:
            return 1.530
        }
    }
}

enum Lang: String, Identifiable {
    case ja
    case en
    case multi
    
    // just for ForEach operation
    var id: String { rawValue }

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
