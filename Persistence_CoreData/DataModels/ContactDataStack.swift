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
    private(set) var persistenceStoreURL: URL?
    
    init(dataModel: String = ContactManagedObjectModel.name,
                  persistenStore: String = ContactPersistentStore.name)
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
        
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext?.persistentStoreCoordinator = persistentStoreCoordinator

        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docURL = urls[urls.endIndex - 1]
        let storeURL = docURL.appendingPathComponent(persistenStore)
        print("DataStore path: \(storeURL)")
        
        DispatchQueue.global().async {
            //Use this option for migrations
//            let options = [NSMigratePersistentStoresAutomaticallyOption: true,
//                           NSInferMappingModelAutomaticallyOption: true]
            do {
                try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                                  configurationName: nil,
                                                                  at: storeURL,
                                                                  options: nil)
                
                print("Persisten Store loaded on coordinator")
            } catch {
                assertionFailure("Error migrating store \(error)")
            }
        }
        
        persistenceStoreURL = storeURL
    }
    
    func emptyContactPersistenceStore() -> Bool {
        guard let moc = managedObjectContext else { return false }
        let personRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        let deletePersonRequest = NSBatchDeleteRequest(fetchRequest: personRequest)
        let companyRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Company")
        let deleteCompanyRequest = NSBatchDeleteRequest(fetchRequest: companyRequest)
        
        do {
            try managedObjectContext?.persistentStoreCoordinator?.execute(deletePersonRequest, with: moc)
            try managedObjectContext?.persistentStoreCoordinator?.execute(deleteCompanyRequest, with: moc)
            return true
        } catch let error as NSError {
            print("Error deleting data from DB: \(error)")
            return false
        }
    }
    
}
