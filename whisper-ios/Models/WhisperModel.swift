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
    var needsSubscription: Bool
    var createdAt: Date
    var updatedAt: Date

    init(size: Size, language: Lang, needsSubscription: Bool = false, callBack: @escaping (URL) -> Void) {
        id = UUID()
        self.size = size
        self.language = language
        self.needsSubscription = needsSubscription
        localPath = WhisperModelRepository.fetchWhisperModel(size: size, language: language, needsSubscription: needsSubscription, callBack: callBack)
        // NOTE: This is a UNIX Time
        createdAt = Date()
        updatedAt = Date()
    }

    init(
        id: UUID,
        localPath: URL?,
        size: Size,
        language: Lang,
        needsSubscription: Bool
    ) {
        self.id = id
        self.localPath = localPath
        self.size = size
        self.language = language
        self.needsSubscription = needsSubscription
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var name: String {
        "\(size.rawValue)-\(language.rawValue)"
    }
}
