import Foundation

class Record: Codable, Identifiable {
    var name: String
    var date: Date
    var transcription: String
    var length: Int

    init() {
        self.name = "Record name"
        self.date = Date()
        self.transcription = "transcription"
        self.length = 0
    }
}
