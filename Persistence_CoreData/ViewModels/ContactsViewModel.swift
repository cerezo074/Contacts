//
//  ContactsViewModel.swift
//  Persistence_CoreData
//
//  Created by Eli Pacheco Hoyos on 12/19/16.
//  Copyright © 2016 Eli Pacheco Hoyos. All rights reserved.
//

import Foundation
import CoreData

enum DataState {
    case Iddle
    case Fetching
    case Loaded(error: String?)
}

enum UserActionOnData {
    case Iddle
    case update(indexpath :IndexPath)
    case delete(indexpath :IndexPath)
    case insert(indexpath :IndexPath)
}

typealias ContactsDataStateListener = (_ state: DataState) -> ()
typealias ContactsUserActionOnDataListener = (_ userAction: UserActionOnData) -> ()

class ContactsViewModel: NSObject, ContactsDAO {
    
    var dataListener: ContactsDataStateListener?
    private var dataState: DataState = .Iddle {
        didSet {
            DispatchQueue.main.async {
                [weak self] in
                guard let dataState = self?.dataState else { return }
                self?.dataListener?(dataState)
            }
        }
    }
    
    var userActionOnDataListener: ContactsUserActionOnDataListener?
    private var userActionOnDataState: UserActionOnData = .Iddle {
        didSet{
            userActionOnDataListener?(userActionOnDataState)
        }
    }
    
    private(set) var contactsManagedObjectContext: NSManagedObjectContext
    private(set) var contactsFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    var sections: Int {
        return contactsFetchedResultsController?.sections?.count ?? 0
    }
    
    init(contactsManagedObjectContext: NSManagedObjectContext) {
        self.contactsManagedObjectContext = contactsManagedObjectContext
        super.init()
        registerForNotification()
        setUpContacts()
    }
    
    deinit {
        dataListener = nil
        userActionOnDataListener = nil
        unregisterForNotifications()
    }
    
    func setUpContacts() {
        self.dataState = .Fetching
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        let firstnameSortDescriptor = NSSortDescriptor(key: "firstname", ascending: true)
        let lastnameSortDescriptor = NSSortDescriptor(key: "lastname", ascending: true)
        request.sortDescriptors = [firstnameSortDescriptor, lastnameSortDescriptor]
        self.contactsFetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: contactsManagedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        self.contactsFetchedResultsController?.delegate = self
        
        do {
            try self.contactsFetchedResultsController?.performFetch()
            self.dataState = .Loaded(error: nil)
        } catch {
            print("Error fetcing results on fetched results controller.")
            self.dataState = .Loaded(error: "Contacts can't be loaded, please contact support")
        }
    }
    
    func contactAtIndex(_ index: IndexPath) -> Person? {
        return contactsFetchedResultsController?.object(at: index) as? Person
    }
    
    func numbersOfContactsForSection(_ at: Int) -> Int {
        return contactsFetchedResultsController?.sections?[at].numberOfObjects ?? 0
    }
    
    func contactSubtitleInfo(contact: Person) -> String {
        guard let email = contact.email else {
            return "Contact without email"
        }
        return "Email: \(email)"
    }
    
    func titleInfo(contact: Person) -> String {
        guard let firstName = contact.firstname, let lastname = contact.lastname else {
            return "Contact without title"
        }
        
        return firstName.capitalized + " " + lastname.capitalized
    }
    
    func deleteContact(_ at: IndexPath) {
        guard let person = contactsFetchedResultsController?.object(at: at) as? Person,
            let personIdentifier = person.identifier else {
            return
        }
        do {
            let deletePersonRequest = createRequestWith("Person",
                                                        "identifier ==[cd] %@",
                                                        [personIdentifier])
            let _ = try delete(validationRequest: deletePersonRequest)
        } catch {
            print("Error deleting the object \(person)\nError: \(error)")
        }
    }
    
    //MARK: Notification Methods
    
    func registerForNotification() {
        let storeHasChangedSelector = #selector(CreatePersonViewModel.storeHasChanged(notification:))
        NotificationCenter.default.addObserver(self,
                                               selector: storeHasChangedSelector,
                                               name: NSNotification.Name.NSManagedObjectContextDidSave,
                                               object: nil)
    }
    
    func unregisterForNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.NSManagedObjectContextDidSave,
                                                  object: nil)
    }
    
    func storeHasChanged(notification: Notification) {
        guard let moc = notification.object as? NSManagedObjectContext,
            moc != contactsManagedObjectContext else { return }
        
        if contactsManagedObjectContext.persistentStoreCoordinator != moc.persistentStoreCoordinator {
            return
        }
        
        contactsManagedObjectContext.mergeChanges(fromContextDidSave: notification)
    }
    
}

extension ContactsViewModel: NSFetchedResultsControllerDelegate {

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            guard let index = indexPath else { return }
            userActionOnDataListener?(.delete(indexpath: index))
            break
        case .insert:
            guard let index = newIndexPath else { return }
            userActionOnDataListener?(.insert(indexpath: index))
            break
        case .update:
            guard let index = indexPath else { return }
            userActionOnDataListener?(.update(indexpath: index))
            break
        case .move:
            break
        }
    }
    
}
