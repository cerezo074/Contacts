//
//  ContactsDAO.swift
//  Persistence_CoreData
//
//  Created by Eli Pacheco Hoyos on 12/19/16.
//  Copyright © 2016 Eli Pacheco Hoyos. All rights reserved.
//

import Foundation
import CoreData

protocol ContactsDAO {
    var contactsManagedObjectContext: NSManagedObjectContext { get set }
}

enum ContactsDAOReadingErrors: Error {
    case readFailed
    case invalidEntities
}

enum ContacsDAOCreatingErrors: Error {
    case emailInvalid
    case contactExist
    case companyBelongsDifferentMOC
    case creationFailed
}

extension ContactsDAO {
    
    func create(firstName: String,
                lastname: String,
                email: String,
                cellPhone: String?,
                identifier: String,
                job: String,
                company: Company?) throws
    {
        let userExistRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        userExistRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
        do {
            let usersFetched = try contactsManagedObjectContext.fetch(userExistRequest)
            if usersFetched.count > 0 {
                throw ContacsDAOCreatingErrors.contactExist
            }
            if company?.managedObjectContext != contactsManagedObjectContext {
                throw ContacsDAOCreatingErrors.companyBelongsDifferentMOC
            }
            guard let newContact = NSEntityDescription.insertNewObject(
                forEntityName: "Person",
                into: contactsManagedObjectContext) as? Person else {
                    return
            }
            
            newContact.firstname = firstName
            newContact.lastname = lastname
            newContact.email = email
            newContact.cellphone = cellPhone
            newContact.identifier = identifier
            newContact.job = job
            newContact.company = company
            company?.addToEmployee(newContact)
            
            do {
                try contactsManagedObjectContext.save()
            } catch {
                print("Error creating the new Contact: \(error)")
                throw ContacsDAOCreatingErrors.creationFailed
            }
        }
    }
    
    func delete() {
    
    }
    
    func readContacts(fetchRequest: NSFetchRequest<NSFetchRequestResult>) throws -> [Person] {
        do {
            let contactsFetched = try contactsManagedObjectContext.fetch(fetchRequest)
            guard let contactsArray = contactsFetched as? [Person] else {
                throw ContactsDAOReadingErrors.invalidEntities
            }
            return contactsArray
        } catch {
            print("Error reading Persons: \(error)")
            throw ContactsDAOReadingErrors.readFailed
        }
    }
    
}
