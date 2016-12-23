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

class ContactsViewModel: NSObject {
    
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
    
    private(set) var contactsFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    var sections: Int {
        return contactsFetchedResultsController?.sections?.count ?? 0
    }
    
    init(contactsController: ContactDataStack) {
        super.init()
        
        DispatchQueue.global().async { [weak self, weak contactsController] in
            let errorMessage = "Data can't be loaded."
            self?.dataState = .Fetching
            
            guard let moc = contactsController?.managedObjectContext else {
                print("Error creating fetched result controller, there isn't context!!!.")
                self?.dataState = .Loaded(error: errorMessage)
                return
            }
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
            let firstnameSortDescriptor = NSSortDescriptor(key: "firstname", ascending: true)
            let lastnameSortDescriptor = NSSortDescriptor(key: "lastname", ascending: true)
            request.sortDescriptors = [firstnameSortDescriptor, lastnameSortDescriptor]
            self?.contactsFetchedResultsController = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: moc,
                sectionNameKeyPath: nil,
                cacheName: nil)
            self?.contactsFetchedResultsController?.delegate = self
            
            do {
                try self?.contactsFetchedResultsController?.performFetch()
                self?.dataState = .Loaded(error: nil)
            } catch {
                print("Error fetcing results on fetched results controller.")
                self?.dataState = .Loaded(error: errorMessage)
            }
        }
    }
    
    func contactAtIndex(_ index: IndexPath) -> Person? {
        let contact = self.contactsFetchedResultsController?.object(at: index) as? Person
        return contact
    }
    
    func numbersOfContactsForSection(_ at: Int) -> Int {
        guard let section = self.contactsFetchedResultsController?.sections?[at] else { return 0 }
        return section.numberOfObjects
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
