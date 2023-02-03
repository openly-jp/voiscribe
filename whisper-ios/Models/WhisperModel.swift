import Foundation

enum Size: String {
    case tiny
    case base
    case small

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
    @Published var isDownloaded: Bool
    var recordDownloadedModels: RecordDownloadedModels = .init()
    var needsSubscription: Bool
    var createdAt: Date
    var updatedAt: Date

    init(size: Size, language: Lang, needsSubscription: Bool = false) {
        id = UUID()
        self.size = size
        self.language = language
        self.needsSubscription = needsSubscription
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
            .fetchWhisperModel(size: size, language: language, needsSubscription: needsSubscription) { result in
                switch result {
                case let .success(modelURL):
                    self.localPath = modelURL
                    self.isDownloaded = true
                    self.recordDownloadedModels.setRecordDownloadedModels(
                        size: size.rawValue,
                        lang: language.rawValue,
                        isDownloaded: true
                    )
                case let .failure(error):
                    self.isDownloaded = false
                    print("Error: \(error.localizedDescription)")
                }
            }
    }

    init(
        localPath: URL?,
        size: Size,
        language: Lang,
        needsSubscription: Bool
    ) {
        id = UUID()
        self.localPath = localPath
        self.size = size
        self.language = language
        isDownloaded = true
        self.needsSubscription = needsSubscription
        createdAt = Date()
        updatedAt = Date()
    }

    var name: String {
        "\(size.rawValue)-\(language.rawValue)"
    }
}
