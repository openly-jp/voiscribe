import Foundation

enum Size: String, CaseIterable, Identifiable {
    case base
    case small
    case medium

    init() {
        guard let deviceLanguageCode = Locale(identifier: Locale.preferredLanguages.first!).languageCode else {
            self = .small
            return
        }

        if deviceLanguageCode == "ja" {
            self = .small
        } else {
            self = .small
        }
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
}

enum Lang: String, Identifiable, CaseIterable {
    case ja
    case en
    case multi

    // just for ForEach operation
    var id: String { rawValue }

    init() {
        guard let deviceLanguageCode = Locale(identifier: Locale.preferredLanguages.first!).languageCode else {
            self = .en
            return
        }

        if deviceLanguageCode == "ja" {
            self = .multi
        } else {
            self = .en
        }
    }
}

func getModelMegaBytes(
    size: Size,
    lang: Lang
) -> Int {
    switch (size, lang) {
    case (Size.base, Lang.en):
        return 148
    case (Size.base, Lang.multi):
        return 148
    case (Size.small, Lang.en):
        return 160
    case (Size.small, Lang.multi):
        return 488
    case (Size.medium, Lang.en):
        return 469
    case (Size.medium, Lang.multi):
        return 1530
    default:
        return -1
    }
}

let userDefaultWhisperModelDownloadPrefix = "user-default-whisper-model-download" // "-" + size + "-" + lang
let userDefaultWhisperModelDownloadingPrefix = "user-default-whisper-model-downloading" // "-" + size + "-" + lang

class WhisperModel: Identifiable, ObservableObject {
    var localPath: URL?
    var size: Size
    var language: Lang
    var whisperContext: OpaquePointer?

    @Published var isDownloaded: Bool

    init(size: Size, language: Lang) {
        self.size = size
        self.language = language

        isDownloaded = WhisperModelRepository.modelExists(
            size: size,
            language: language
        )

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
        isDownloaded = WhisperModelRepository.modelExists(
            size: size,
            language: language
        )
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

        // Do serial processing instead of parallel processing for model loading
        // to prevent recognition from starting before model is loaded
        whisperContext = whisper_init_from_file(modelUrl.path)

        var err: Error?
        if whisperContext == nil {
            err = NSError(domain: "Failed to load model", code: -1)
        }

        callback(err)
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
