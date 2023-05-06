import CoreData
import Foundation

extension CoreDataRepository {
    static func saveRecognizedSpeech(_ recognizedSpeech: RecognizedSpeech) {
        let rsEntity = RecognizedSpeechData.new(recognizedSpeech: recognizedSpeech)

        for tl in rsEntity.transcriptionLines {
            CoreDataRepository.add(tl as! NSManagedObject)
        }

        CoreDataRepository.add(rsEntity)
        CoreDataRepository.save()
    }

    static func addTranscriptionLinesToRecognizedSpeech(
        recognizedSpeech: RecognizedSpeech,
        transcriptionLines: [TranscriptionLine]
    ) {
        guard let rsEntity: RecognizedSpeechData = CoreDataRepository.getById(uuid: recognizedSpeech.id) else {
            fatalError("object with id: \(recognizedSpeech.id.uuidString) is not found.")
        }
        guard let rsContext = rsEntity.managedObjectContext else {
            fatalError("context with id: \(recognizedSpeech.id.uuidString) is not found.")
        }
        for tl in transcriptionLines {
            let tlEntity = TranscriptionLineData.new(tl, inContext: rsContext)
            tlEntity.recognizedSpeech = rsEntity
            rsEntity.addToTranscriptionLines(tlEntity)
            CoreDataRepository.add(tlEntity)
        }

        CoreDataRepository.update(rsEntity)
        CoreDataRepository.save()
    }

    static func getAllRecognizedSpeeches() -> [RecognizedSpeech] {
        let request = RecognizedSpeechData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        let res = CoreDataRepository.fetch(request)
        return res.map { rsd in RecognizedSpeechData.toModel(recognizedSpeechData: rsd) }
    }

    static func deleteRecognizedSpeech(recognizedSpeech: RecognizedSpeech) {
        guard let rsEntity: RecognizedSpeechData = CoreDataRepository.getById(uuid: recognizedSpeech.id) else {
            fatalError("object with id: \(recognizedSpeech.id.uuidString) is not found.")
        }

        CoreDataRepository.delete(rsEntity)
        CoreDataRepository.save()
    }
}
