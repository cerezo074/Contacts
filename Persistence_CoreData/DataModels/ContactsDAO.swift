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

enum PersonCreatingErrors: Error {
    case emailInvalid
    case personExist
    case companyBelongsDifferentMOC
    case creationFailed
}

enum CompanyCreatingErrors: Error {
    case companyExist
    case creationFailed
}

extension ContactsDAO {
    
    func createPerson(firstName: String,
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
                throw PersonCreatingErrors.personExist
            }
            if company?.managedObjectContext != contactsManagedObjectContext {
                throw PersonCreatingErrors.companyBelongsDifferentMOC
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
                throw PersonCreatingErrors.creationFailed
            }
        }
    }
    
    func createCompany() throws {
    
    }
    
    func delete() {
    
    }
    
    func read<T: NSManagedObject>(fetchRequest: NSFetchRequest<NSFetchRequestResult>) throws -> [T] {
        do {
            let contactsFetched = try contactsManagedObjectContext.fetch(fetchRequest)
            guard let contactsArray = contactsFetched as? [T] else {
                throw ContactsDAOReadingErrors.invalidEntities
            }
            return contactsArray
        } catch {
            print("Error reading Persons: \(error)")
            throw ContactsDAOReadingErrors.readFailed
        }
    }
    
}
