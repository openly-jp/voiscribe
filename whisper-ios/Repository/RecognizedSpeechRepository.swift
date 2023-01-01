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
    
    static func getAll() -> [RecognizedSpeech] {
        var list: [RecognizedSpeechData] = CoreDataRepository.array()
        return list.map { rsd in RecognizedSpeechData.toModel(aRecognizedSpeechData: rsd)}
    }
}

