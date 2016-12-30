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
    var contactsManagedObjectContext: NSManagedObjectContext { get }
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

let indepentCompanyName = "Indepent"

extension ContactsDAO {
    
    func allPersons() -> [Person]? {
        let allPersonsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        do {
            return try read(fetchRequest: allPersonsRequest) as? [Person]
        } catch {
            print("Error fetching all Persons: \(error)")
            return nil
        }
    }
    
    func allCompanies() -> [Company]? {
        let allPersonsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Company")
        do {
            return try read(fetchRequest: allPersonsRequest) as? [Company]
        } catch {
            print("Error fetching all Companies: \(error)")
            return nil
        }
    }
    
    func deleteAllPersons() -> Bool {
        let personsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        do {
            guard let persons = try contactsManagedObjectContext.fetch(personsRequest) as? [Person] else {
                return false
            }
            
            for person in persons {
                if let company = person.company {
                    company.removeFromEmployee(person)
                    person.company = nil
                }
                contactsManagedObjectContext.delete(person)
                try contactsManagedObjectContext.save()
            }
            
            let readPersonsAgainRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
            let personsAfterDeleted = try read(fetchRequest: readPersonsAgainRequest)
            return personsAfterDeleted.count == 0
        } catch {
            print("Error deleting all Persons: \(error)")
            return false
        }
    }
    
    func deleteAllCompanies() -> Bool {
        let companiesRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Company")
        do {
            guard let companies = try contactsManagedObjectContext.fetch(companiesRequest) as? [Company] else {
                return false
            }
            
            for company in companies {
                if let employees = company.employee {
                    for employee in employees {
                        if let employee = employee as? Person {
                            company.removeFromEmployee(employee)
                            employee.company = nil
                            try contactsManagedObjectContext.save()
                        }
                    }
                }
                
                contactsManagedObjectContext.delete(company)
                try contactsManagedObjectContext.save()
            }
            
            let companiesReadAgainRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Company")
            let companiesAfterDeleted = try read(fetchRequest: companiesReadAgainRequest)
            return companiesAfterDeleted.count == 0
        } catch {
            print("Error deleting all Persons: \(error)")
            return false
        }
    }
    
    func emptyContactPersistenceStore() -> Bool {
        return deleteAllPersons() && deleteAllCompanies()
    }
    
    func createPerson(firstName: String,
                      lastname: String,
                      email: String,
                      cellPhone: String,
                      identifier: String,
                      job: String,
                      company: Company?) throws -> Person?
    {
        let userExistRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        userExistRequest.predicate = NSPredicate(format: "identifier ==[cd] %@", identifier)
        let usersFetched = try contactsManagedObjectContext.fetch(userExistRequest)
        if usersFetched.count > 0 {
            throw PersonCreatingErrors.personExist
        }
        if let companyToSave = company, companyToSave.managedObjectContext != contactsManagedObjectContext {
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
        
        try newContact.validateForInsert()
        try contactsManagedObjectContext.save()
        return newContact
    }
    
    func createCompany(name: String,
                       email: String,
                       address: String,
                       telephone: String) throws -> Company?
    {
        let companyExistRequestValidator = NSFetchRequest<NSFetchRequestResult>(entityName: "Company")
        companyExistRequestValidator.predicate = NSPredicate(format: "identifier ==[cd] %@", name)
        let companyFetched = try contactsManagedObjectContext.fetch(companyExistRequestValidator)
        if companyFetched.count > 0 {
            throw CompanyCreatingErrors.companyExist
        }
        guard let newCompany = NSEntityDescription.insertNewObject(
            forEntityName: "Company",
            into: contactsManagedObjectContext) as? Company else {
                throw ContactsCommonErros.invalidEntity
        }
        
        newCompany.identifier = name
        newCompany.name = name
        newCompany.email = email
        newCompany.address = address
        newCompany.telephone = telephone
        
        try newCompany.validateForInsert()
        try contactsManagedObjectContext.save()
        return newCompany
    }
    
    func delete(validationRequest: NSFetchRequest<NSFetchRequestResult>) throws -> Bool {
        if let result = try? contactsManagedObjectContext.fetch(validationRequest) {
            for object in result {
                guard let objectToDelete = object as? NSManagedObject else {
                    throw ContactsCommonErros.invalidEntity
                }
                
                //Person entity(Weak entity) has a relationship with the Company entity(Strong entity)
                if objectToDelete is Person, let person = object as? Person {
                    let company = person.company
                    company?.removeFromEmployee(person)
                    person.company = nil
                    contactsManagedObjectContext.delete(person)
                    try contactsManagedObjectContext.save()
                    return true
                } else {
                    //Objects without restrictions
                    contactsManagedObjectContext.delete(objectToDelete)
                    try contactsManagedObjectContext.save()
                    return true
                }
            }
        } else {
            print("Object to delete not exits on Data Store")
            throw ContactsCommonErros.objectNoExist
        }
        
        return false
    }
    
    func read(fetchRequest: NSFetchRequest<NSFetchRequestResult>) throws -> [NSManagedObject] {
        let contactsFetched = try contactsManagedObjectContext.fetch(fetchRequest)
        guard let contactsArray = contactsFetched as? [NSManagedObject] else {
            throw ContactsCommonErros.invalidEntity
        }
        return contactsArray
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
        try contactsManagedObjectContext.save()
    }
    
    func companyWith(_ name: String) -> Company? {
        let companyRequest = createRequestWith("Company", "identifier ==[cd] %@", [name])
        
        do {
            guard let companiesFetched = try read(fetchRequest: companyRequest) as? [Company] else {
                return nil
            }
            return companiesFetched.first
        } catch {
            print("Error reading the company: \(error)")
            return nil
        }
    }
    
    func personWith(_ identifier: String) -> Person? {
        let personRequest = createRequestWith("Person", "identifier ==[cd] %@", [identifier])
        
        do {
            guard let personsFetched = try read(fetchRequest: personRequest) as? [Person] else {
                return nil
            }
            return personsFetched.first
        } catch {
            print("Error reading the person: \(error)")
            return nil
        }
    }
    
    func createRequestWith(_ entityName: String, _ predicateFormat: String, _ arguments: [Any]) -> NSFetchRequest<NSFetchRequestResult> {
        let fetchedRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchedRequest.predicate = NSPredicate(format: predicateFormat, argumentArray: arguments)
        
        return fetchedRequest
    }
    
}
