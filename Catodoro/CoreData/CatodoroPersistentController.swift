//
//  CatodoroPersistentController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import CoreData

struct CatodoroPersistentController {
    static let shared = CatodoroPersistentController()
    let container: NSPersistentContainer

    static var preview: CatodoroPersistentController = {
        let result = CatodoroPersistentController(inMemory: true)
        let viewContext = result.container.viewContext
        return result
    }()

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CatodoroCoreData")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
