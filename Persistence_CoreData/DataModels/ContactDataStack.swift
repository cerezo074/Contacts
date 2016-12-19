//
//  ContactDataStack.swift
//  Persistence_CoreData
//
//  Created by Eli Pacheco Hoyos on 12/16/16.
//  Copyright © 2016 Eli Pacheco Hoyos. All rights reserved.
//

import UIKit
import CoreData

class ContactDataStack: NSObject {
    
    struct ContactManagedObjectModel {
        static let name = "ContactModel"
        static let fileExtension = "momd"
    }
    
    struct ContactPersistentStore {
        static let name = "ContactModel.sqlite"
    }
    
    var managedObjectContext: NSManagedObjectContext?
    
    override init() {
        guard let managedObjectModelPath = Bundle.main.url(forResource: ContactManagedObjectModel.name,
                                                       withExtension: ContactManagedObjectModel.fileExtension) else {
                                                        assertionFailure("Error loading contact scheme path.")
                                                        return
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: managedObjectModelPath) else {
            assertionFailure("Error loading contact scheme")
            return
        }
        
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext?.persistentStoreCoordinator = persistentStoreCoordinator
        
        DispatchQueue.global().async {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let docURL = urls[urls.endIndex - 1]
            let storeURL = docURL.appendingPathComponent(ContactPersistentStore.name)
            print("DataStrore path: \(storeURL)")
            
            do {
                try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                                  configurationName: nil,
                                                                  at: storeURL,
                                                                  options: nil)
                
                print("Persisten Store loaded on coordinator")
            } catch {
                assertionFailure("Error migrating strore \(error)")
            }
        }
    }
    
}
