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

class WhisperModel: Identifiable {
    let id: UUID
    var localPath: URL?
    var size: Size
    var language: Lang
    var whisperContext: OpaquePointer?
    @Published var isDownloaded: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        size: Size,
        language: Lang,
        completion: @escaping () -> Void
    ) {
        id = UUID()
        self.size = size
        self.language = language
        localPath = URL(string: Bundle.main.path(forResource: "ggml-tiny.en", ofType: "bin")!)!
        if size.rawValue == "tiny" {
            isDownloaded = true
        } else {
            isDownloaded = false
        }
        // NOTE: This is a UNIX Time
        createdAt = Date()
        updatedAt = Date()
        WhisperModelRepository
            .fetchWhisperModel(size: size, language: language,
                               update: nil) { result in
                switch result {
                case let .success(modelURL):
                    self.localPath = modelURL
                    self.isDownloaded = true
                    completion()
                case let .failure(error):
                    self.isDownloaded = false
                    print("Error: \(error.localizedDescription)")
                }
            }
    }

    init(
        localPath: URL?,
        size: Size,
        language: Lang
    ) {
        id = UUID()
        self.localPath = localPath
        self.size = size
        self.language = language
        isDownloaded = true
        createdAt = Date()
        updatedAt = Date()
    }

    var name: String {
        "\(size.rawValue)-\(language.rawValue)"
    }

    func load_model(callback: @escaping () -> Void) {
        Logger.debug("Loading Model: model size \(size), model language \(language.rawValue), model name \(name)")
        guard let modelUrl = localPath else {
            Logger.error("Failed to parse model url")
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.whisperContext = whisper_init_from_file(modelUrl.path)
            if self.whisperContext == nil {
                Logger.error("Failed to load model")
            } else {
                Logger.debug("Model loaded")
                DispatchQueue.main.async {
                    callback()
                }
            }
        }
    }

    // prefer this fucntion to deinit cause
    // we can avoid two models are loaded simultaneouly
    // (for a short amout of time)
    func free_model(callback _: @escaping () -> Void) {
        whisper_free(whisperContext)
    }
}
