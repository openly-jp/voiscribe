import CoreData
import FirebaseCrashlytics
import Foundation

@objc(TranscriptionLineData)
public class TranscriptionLineData: NSManagedObject {
    static func update(_ tl: TranscriptionLine) {
        guard let tlEntity: TranscriptionLineData = CoreDataRepository.getById(uuid: tl.id) else {
            Crashlytics.crashlytics().record(error: fatalError("object with id: \(tl.id.uuidString) is not found."))
        }

        tlEntity.id = tl.id
        tlEntity.startMSec = tl.startMSec
        tlEntity.endMSec = tl.endMSec
        tlEntity.text = tl.text
        tlEntity.ordering = tl.ordering
        tlEntity.createdAt = tl.createdAt
        tlEntity.updatedAt = tl.updatedAt

        CoreDataRepository.save()
    }
}
