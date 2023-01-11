import Foundation
import CoreData

extension CoreDataRepository {
    static func saveRecognizedSpeech(aRecognizedSpeech: RecognizedSpeech) {
        let rsEntity = RecognizedSpeechData.new(aRecognizedSpeech: aRecognizedSpeech)

        for tl in rsEntity.transcriptionLines {
            CoreDataRepository.add(tl as! NSManagedObject)
        }

        CoreDataRepository.add(rsEntity)
        CoreDataRepository.save()
    }

    static func getAllRecognizedSpeeches() -> [RecognizedSpeech] {
        let request = RecognizedSpeechData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        let res = CoreDataRepository.fetch(request)
        return res.map { rsd in RecognizedSpeechData.toModel(aRecognizedSpeechData: rsd)}
    }

    static func deleteRecognizedSpeech(recognizedSpeech: RecognizedSpeech) {
        guard let rsEntity: RecognizedSpeechData = CoreDataRepository.getById(uuid: recognizedSpeech.id) else {
            fatalError("object with id: \(recognizedSpeech.id.uuidString) is not found.")
        }

        CoreDataRepository.delete(rsEntity)
        CoreDataRepository.save()
    }
}

