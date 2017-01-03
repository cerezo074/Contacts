//
//  ContactDataStack.swift
//  Persistence_CoreData
//
//  Created by Eli Pacheco Hoyos on 12/16/16.
//  Copyright © 2016 Eli Pacheco Hoyos. All rights reserved.
//

import UIKit
import CoreData

let PersistentStoreWasLoadedNotification = NSNotification.Name("PersistenStoreWasLoadedNotification")

class ContactDataStack: NSObject {
    
    struct ContactManagedObjectModel {
        static let name = "ContactModel"
        static let fileExtension = "momd"
    }
    
    struct ContactPersistentStore {
        static let name = "ContactModel"
        static let fileExtension = ".sqlite"
    }
    
    var mainContext: NSManagedObjectContext?
    var persistenceStoreCoordinator: NSPersistentStoreCoordinator?
    private(set) var persistenceStoreURL: URL?
    
    init(dataModel: String = ContactManagedObjectModel.name,
         persistenStore: String = ContactPersistentStore.name
        )
    {
        
        guard let managedObjectModelPath = Bundle.main.url(forResource: dataModel,
                                                       withExtension: ContactManagedObjectModel.fileExtension) else {
                                                        assertionFailure("Error loading contact scheme path.")
                                                        return
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: managedObjectModelPath) else {
            assertionFailure("Error loading contact scheme")
            return
        }
        
        let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainContext?.persistentStoreCoordinator = storeCoordinator
        mainContext?.undoManager = nil
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docURL = urls[urls.endIndex - 1]
        let storeURL = docURL.appendingPathComponent(persistenStore + ContactPersistentStore.fileExtension)
        print("DataStore path: \(storeURL)")
        DispatchQueue.global().async {
            //Use this option for migrations
//            let options = [NSMigratePersistentStoresAutomaticallyOption: true,
//                           NSInferMappingModelAutomaticallyOption: true]
            do {
                try storeCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                                  configurationName: nil,
                                                                  at: storeURL,
                                                                  options: nil)
                NotificationCenter.default.post(name: PersistentStoreWasLoadedNotification,
                                                object: nil)
                print("Persisten Store loaded on coordinator")
            } catch {
                assertionFailure("Error adding persistence store \(error)")
            }
        }
        
        persistenceStoreURL = storeURL
        self.persistenceStoreCoordinator = storeCoordinator
    }
    
    func saveContext() -> NSManagedObjectContext? {
        guard let storeCoordinator = persistenceStoreCoordinator else {
            return nil
        }
        
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.persistentStoreCoordinator = storeCoordinator
        privateContext.undoManager = nil
        
        return privateContext
    }
    
}
