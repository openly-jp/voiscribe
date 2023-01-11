import Foundation

class TranscriptionLine: Identifiable {
    let id: UUID
    var startMSec: Int64
    var endMSec: Int64
    var text: String
    var ordering: Int32
    var createdAt: Date
    var updatedAt: Date
    
    init(startMSec: Int64, endMSec: Int64, text: String, ordering: Int32) {
        self.id = UUID()
        self.startMSec = startMSec
        self.endMSec = endMSec
        self.text = text
        self.ordering = ordering
        // NOTE: This is a UNIX Time
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    init(
        id: UUID,
        startMSec: Int64,
        endMSec: Int64,
        text: String,
        ordering: Int32,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.startMSec = startMSec
        self.endMSec = endMSec
        self.text = text
        self.ordering = ordering
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
