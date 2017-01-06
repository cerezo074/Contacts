//
//  ContactDataStack.swift
//  Persistence_CoreData
//
//  Created by Eli Pacheco Hoyos on 12/16/16.
//  Copyright © 2016 Eli Pacheco Hoyos. All rights reserved.
//

import UIKit
import CoreData

@objc protocol ContextHasChangedProtocol {
    func storeShouldChange(notification: Notification)
}

extension ContextHasChangedProtocol {
    
    func registerForDidSaveNotification(obj: Any) {
        let selector = #selector(ContextHasChangedProtocol.storeShouldChange(notification:))
        NotificationCenter.default.addObserver(obj,
                                               selector: selector,
                                               name: NSNotification.Name.NSManagedObjectContextDidSave,
                                               object: nil)
    }
    
    func unregisterForDidSaveNotification(obj: Any) {
        NotificationCenter.default.removeObserver(obj,
                                                  name: NSNotification.Name.NSManagedObjectContextDidSave,
                                                  object: nil)
    }
    
}

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
    
    private(set) var persistenceContext: NSManagedObjectContext?
    private(set) var mainContext: NSManagedObjectContext?
    
    private(set) var managedObjectModel: NSManagedObjectModel?
    private(set) var persistenceStoreCoordinator: NSPersistentStoreCoordinator?
    private(set) var persistenceStoreURL: URL?
    
    init(dataModel: String = ContactManagedObjectModel.name,
         persistenStore: String = ContactPersistentStore.name) {
        
        super.init()

        guard let managedObjectModelPath = Bundle.main.url(forResource: dataModel,
                                                       withExtension: ContactManagedObjectModel.fileExtension) else {
                                                        assertionFailure("Error loading scheme path.")
                                                        return
        }
        
        guard let moModel = NSManagedObjectModel(contentsOf: managedObjectModelPath) else {
            assertionFailure("Error loading scheme")
            return
        }
        
        let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: moModel)
        
        persistenceContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistenceContext?.persistentStoreCoordinator = storeCoordinator
        persistenceContext?.undoManager = nil
        
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
        managedObjectModel = moModel
        persistenceStoreCoordinator = storeCoordinator
        
        registerForDidSaveNotification(obj: self)
    }
    
    deinit {
        unregisterForDidSaveNotification(obj: self)
    }
    
    func saveContext() -> NSManagedObjectContext {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = mainContext
        privateContext.undoManager = nil
        
        return privateContext
    }
    
}

extension ContactDataStack: ContextHasChangedProtocol {

    func storeShouldChange(notification: Notification) {
        guard let moc = notification.object as? NSManagedObjectContext,
        let parent = moc.parent,
        let main = mainContext,
        let persistent = persistenceContext else {
            return
        }
        
        if parent == main {
            saveChangesOnMainMOC()
        }
        
        if parent == persistent {
            saveChangesOnPersistentMOC()
        }
    }
    
    func saveChangesOnMainMOC() {
        guard let mainMOC = self.mainContext
            else {
                print("You are trying to save without a mainMOC")
                return
        }
        
        if !mainMOC.hasChanges {
            print("You doesn't have changes on main context!")
            return
        }
        
        unowned let unownedMainMOC = mainMOC
        mainMOC.perform {
            do {
                try unownedMainMOC.save()
                print("Changes was saved on main context!")
            } catch {
                print("Error trying to saving changes on main context: \(error)")
            }
        }
    }
    
    func saveChangesOnPersistentMOC() {
        guard let persistentMOC = self.persistenceContext
            else {
                print("You are trying to save without a persistenMOC")
                return
        }
        
        if !persistentMOC.hasChanges {
            print("You doesn't have changes on persistent context!")
            return
        }
        
        unowned let unownedPersistentMOC = persistentMOC
        persistentMOC.perform {
            do {
                try unownedPersistentMOC.save()
                print("Changes was saved on persisten context!")
            } catch {
                print("Error trying to saving changes on persitence context: \(error)")
            }
        }
    }
    
}
