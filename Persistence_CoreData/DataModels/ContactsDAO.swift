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

enum PersonCreatingErrors: Error {
    case emailInvalid
    case personExist
    case creationFailed
}

enum CompanyCreatingErrors: Error {
    case companyExist
    case creationFailed
}

enum ContactsCommonErros: Error {
    case invalidEntity
    case invalidPredicate
    case objectNoExist
    case unknowErrorOnOperation
    case objectBelongsDifferentMOC
}

extension ContactsDAO {
    
    func createPerson(firstName: String,
                      lastname: String,
                      email: String,
                      cellPhone: String?,
                      identifier: String,
                      job: String,
                      company: Company?) throws -> Person?
    {
        let userExistRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        userExistRequest.predicate = NSPredicate(format: "identifier ==[cd] %@", identifier)
        do {
            let usersFetched = try contactsManagedObjectContext.fetch(userExistRequest)
            if usersFetched.count > 0 {
                throw PersonCreatingErrors.personExist
            }
            if company?.managedObjectContext != contactsManagedObjectContext {
                throw ContactsCommonErros.objectBelongsDifferentMOC
            }
            guard let newContact = NSEntityDescription.insertNewObject(
                forEntityName: "Person",
                into: contactsManagedObjectContext) as? Person else {
                    throw ContactsCommonErros.invalidEntity
            }
            
            newContact.firstname = firstName
            newContact.lastname = lastname
            newContact.email = email
            newContact.cellphone = cellPhone
            newContact.identifier = identifier
            newContact.job = job
            newContact.company = company
            company?.addToEmployee(newContact)
            
            try contactsManagedObjectContext.save()
            return newContact
        } catch {
            print("Error creating the new Contact: \(error)")
            throw PersonCreatingErrors.creationFailed
        }
    }
    
    func createCompany(name: String,
                       email: String,
                       address: String,
                       telephone: String) throws -> Company?
    {
        let companyExistRequestValidator = NSFetchRequest<NSFetchRequestResult>(entityName: "Company")
        companyExistRequestValidator.predicate = NSPredicate(format: "identifier ==[cd] %@", name)
        
        do {
            let companyFetched = try contactsManagedObjectContext.fetch(companyExistRequestValidator)
            if companyFetched.count > 0 {
                throw CompanyCreatingErrors.companyExist
            }
            guard let newCompany = NSEntityDescription.insertNewObject(
                forEntityName: "Company",
                into: contactsManagedObjectContext) as? Company else {
                throw ContactsCommonErros.invalidEntity
            }
            
            newCompany.name = name
            newCompany.email = email
            newCompany.address = address
            newCompany.telephone = telephone
            
            try contactsManagedObjectContext.save()
            return newCompany
        } catch {
            print("Error creating the new Company: \(error)")
            throw CompanyCreatingErrors.creationFailed
        }
    }
    
    func delete(validationRequest: NSFetchRequest<NSFetchRequestResult>) throws {
        if let result = try? contactsManagedObjectContext.fetch(validationRequest) {
            for object in result {
                guard let objectToDelete = object as? NSManagedObject else {
                    throw ContactsCommonErros.invalidEntity
                }
                contactsManagedObjectContext.delete(objectToDelete)
            }
        } else {
            print("Object to delete not exits on Data Store")
            throw ContactsCommonErros.objectNoExist
        }
    }
    
    func read<T: NSManagedObject>(fetchRequest: NSFetchRequest<NSFetchRequestResult>) throws -> [T] {
        do {
            let contactsFetched = try contactsManagedObjectContext.fetch(fetchRequest)
            guard let contactsArray = contactsFetched as? [T] else {
                throw ContactsCommonErros.invalidEntity
            }
            return contactsArray
        } catch {
            print("Error reading Persons: \(error)")
            throw ContactsCommonErros.unknowErrorOnOperation
        }
    }
    
    func update(_ object: NSManagedObject) throws {
        if object.managedObjectContext != contactsManagedObjectContext {
            throw ContactsCommonErros.objectBelongsDifferentMOC
        }
        
        /*
         Errors created on managed object model are triggered by save function,
         so you can create the error on it and don't need to validate here, they are
         validated automatically by the coordinator.
         */
        do {
            try contactsManagedObjectContext.save()
        }
    }
    
}
