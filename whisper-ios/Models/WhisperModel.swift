import Foundation

enum Size: String {
    case tiny
    case base
    case small
}

enum Lang: String {
    case ja
    case en
    case multi
}

class WhisperModel: Identifiable {
    let id: UUID
    var localPath: String
    var size: Size
    var language: Lang
    var needsSubscription: Bool
    var createdAt: Date
    var updatedAt: Date

    init(localPath _: str, size: Size, language: Lang) {
        id = UUID()
        self.size = size
        self.language = language
        needsSubscription = false
        // NOTE: This is a UNIX Time
        createdAt = Date()
        updatedAt = Date()
    }

    init(
        id: UUID,
        localPath _: String,
        size: Size,
        language: Lang,
        needsSubscription: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.size = size
        self.language = language
        self.needsSubscription = needsSubscription
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
