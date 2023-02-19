import CoreData
import Foundation

@objc(RecognizedSpeechData)
public class RecognizedSpeechData: NSManagedObject {
    static func new(recognizedSpeech: RecognizedSpeech) -> RecognizedSpeechData {
        let rsEntity: RecognizedSpeechData = CoreDataRepository.entity()
        rsEntity.id = recognizedSpeech.id
        rsEntity.title = recognizedSpeech.title
        rsEntity.audioFileURL = recognizedSpeech.audioFileURL
        rsEntity.language = recognizedSpeech.language.rawValue
        rsEntity.createdAt = recognizedSpeech.createdAt
        rsEntity.updatedAt = recognizedSpeech.updatedAt

        for transcriptionLine in recognizedSpeech.transcriptionLines {
            let tlEntity: TranscriptionLineData = CoreDataRepository.entity()
            tlEntity.id = transcriptionLine.id
            tlEntity.startMSec = transcriptionLine.startMSec
            tlEntity.endMSec = transcriptionLine.endMSec
            tlEntity.text = transcriptionLine.text
            tlEntity.ordering = transcriptionLine.ordering
            tlEntity.createdAt = transcriptionLine.createdAt
            tlEntity.updatedAt = transcriptionLine.updatedAt

            tlEntity.recognizedSpeech = rsEntity
            rsEntity.addToTranscriptionLines(tlEntity)
        }
        return rsEntity
    }

    static func toModel(recognizedSpeechData: RecognizedSpeechData) -> RecognizedSpeech {
        let rsModel = RecognizedSpeech(
            id: recognizedSpeechData.id,
            title: recognizedSpeechData.title,
            audioFileURL: recognizedSpeechData.audioFileURL,
            language: Language(rawValue: recognizedSpeechData.language)!,
            transcriptionLines: [],
            createdAt: recognizedSpeechData.createdAt,
            updatedAt: recognizedSpeechData.updatedAt
        )

        let transcriptionLines: [TranscriptionLine] = recognizedSpeechData.transcriptionLines.map { tld in
            let tldEntity = tld as! TranscriptionLineData
            return TranscriptionLine(
                id: tldEntity.id,
                startMSec: tldEntity.startMSec,
                endMSec: tldEntity.endMSec,
                text: tldEntity.text,
                ordering: tldEntity.ordering,
                createdAt: tldEntity.createdAt,
                updatedAt: tldEntity.updatedAt
            )
        }
        // RecognizedSpeechData -> TranscriptionLine relationship is not ordered, so sorting the array just in case
        rsModel.transcriptionLines = transcriptionLines.sorted(by: { $0.ordering < $1.ordering })
        return rsModel
    }

    /// Update recognizedSpeech data model.
    ///
    /// - Note: this method is used for update data model but not transcription lines.
    /// - Parameter rs: recognizedSpeech model
    static func update(_ rs: RecognizedSpeech) {
        guard let rsEntity: RecognizedSpeechData = CoreDataRepository.getById(uuid: rs.id) else {
            fatalError("object with id: \(rs.id.uuidString) is not found.")
        }

        rsEntity.id = rs.id
        rsEntity.title = rs.title
        rsEntity.audioFileURL = rs.audioFileURL
        rsEntity.language = rs.language.rawValue
        rsEntity.createdAt = rs.createdAt
        rsEntity.updatedAt = rs.updatedAt

        CoreDataRepository.save()
    }
}
