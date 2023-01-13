import Foundation

class Record: Codable, Identifiable {
    var name: String
    var date: Date
    var transcription: String
    var length: Int

    init() {
        name = "Record name"
        date = Date()
        transcription = "transcription"
        length = 0
    }
}
