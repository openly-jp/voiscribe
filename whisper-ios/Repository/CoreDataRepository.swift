import CoreData
import FirebaseCrashlytics
import Foundation

class CoreDataRepository {
    init() {}

    private static var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                Crashlytics.crashlytics().record(error: fatalError("Unresolved error \(error), \(error.userInfo)"))
            }
        })
        return container
    }()

    private static var context: NSManagedObjectContext {
        CoreDataRepository.persistentContainer.viewContext
    }
}

// MARK: for Create

extension CoreDataRepository {
    static func entity<T: NSManagedObject>() -> T {
        let entityDescription = NSEntityDescription.entity(
            forEntityName: String(describing: T.self),
            in: context
        )!
        return T(entity: entityDescription, insertInto: nil)
    }
}

// MARK: CRUD

extension CoreDataRepository {
    static func array<T: NSManagedObject>() -> [T] {
        do {
            let request = NSFetchRequest<T>(entityName: String(describing: T.self))
            return try context.fetch(request)
        } catch {
            Crashlytics.crashlytics().record(error: fatalError())
        }
    }

    static func getById<T: NSManagedObject>(uuid: UUID) -> T? {
        do {
            let request = NSFetchRequest<T>(entityName: String(describing: T.self))
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
            return try context.fetch(request).first
        } catch {
            Crashlytics.crashlytics().record(error: fatalError())
        }
    }

    static func add(_ object: NSManagedObject) {
        context.insert(object)
    }

    static func delete(_ object: NSManagedObject) {
        context.delete(object)
    }
}

// MARK: context CRUD

extension CoreDataRepository {
    static func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch let error as NSError {
            Crashlytics.crashlytics().log("\(error), \(error.userInfo)")
        }
    }

    static func rollback() {
        guard context.hasChanges else { return }
        context.rollback()
    }

    static func fetch<T: NSFetchRequestResult>(_ request: NSFetchRequest<T>) -> [T] {
        do {
            return try context.fetch(request)
        } catch let error as NSError {
            Crashlytics.crashlytics().log("\(error), \(error.userInfo)")
            return []
        }
    }
}
