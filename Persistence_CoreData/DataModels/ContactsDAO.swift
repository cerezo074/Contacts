//
//  ContactsDAO.swift
//  Persistence_CoreData
//
//  Created by Eli Pacheco Hoyos on 12/19/16.
//  Copyright © 2016 Eli Pacheco Hoyos. All rights reserved.
//

import Foundation
import CoreData

protocol ContactsDAO: class {
    var managedObjectContextForTask: NSManagedObjectContext { get }
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

typealias PerformTaskBlock = (_ completed: Bool, _ error: Error?) -> Void
typealias PerformTaskWithResultBlock = (_ result: Any?, _ error: Error?) -> Void
typealias PerformTaskWithMultipleResultBlock = (_ result: [Any]?, _ error: Error?) -> Void
typealias ValidationBlock = (Bool?, Bool?) -> Void

extension ContactsDAO {
    
    func resetTemporallyInsertions() {
        managedObjectContextForTask.reset()
    }
    
    func allPersons(completionBlock: @escaping PerformTaskWithMultipleResultBlock) {
        let allPersonsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        managedObjectContextForTask.perform {
            [weak self] in
            
            guard let `self` = self else {
                completionBlock(nil, nil)
                return
            }

            do {
                guard let persons = try self.readSync(fetchRequest: allPersonsRequest) as? [Person] else {
                    completionBlock(nil, Self.createError("Invalid Entity"))
                    return
                }
                completionBlock(persons, nil)
            } catch {
                completionBlock(nil, error)
            }
        }
    }
    
    func allCompanies(completionBlock: @escaping PerformTaskWithMultipleResultBlock) {
        let allCompaniesRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Company")
        managedObjectContextForTask.perform {
            [weak self] in
            
            guard let `self` = self else {
                completionBlock(nil, nil)
                return
            }
            
            do {
                guard let companies = try self.readSync(fetchRequest: allCompaniesRequest) as? [Company] else {
                    completionBlock(nil, Self.createError("Invalid Entity"))
                    return
                }
                completionBlock(companies, nil)
            } catch {
                completionBlock(nil, error)
            }
        }
    }
    
    func deleteAllPersons(completionBlock: @escaping PerformTaskBlock) {
        let personsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        let personsAfectedRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        managedObjectContextForTask.perform {
            [weak self] in
            
            do {
                guard let `self` = self else {
                    completionBlock(false, nil)
                    return
                }
                guard let persons = try self.readSync(fetchRequest: personsRequest) as? [Person] else {
                    completionBlock(false, Self.createError("Invalid Entity"))
                    return
                }
                
                for person in persons {
                    if let company = person.company {
                        company.removeFromEmployee(person)
                        person.company = nil
                    }
                    self.managedObjectContextForTask.delete(person)
                    try self.managedObjectContextForTask.save()
                }
 
                let personsAfterDeleted = try self.readSync(fetchRequest: personsAfectedRequest)
                completionBlock(personsAfterDeleted.count == 0, nil)
            } catch {
                completionBlock(false, error)
            }
        }
    }
    
    func deleteAllCompanies(completionBlock: @escaping PerformTaskBlock) {
        let companiesRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Company")
        let companiesAfectedRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Company")
        managedObjectContextForTask.perform {
            [weak self] in
            
            guard let `self` = self else {
                completionBlock(false, nil)
                return
            }
            
            do {
                guard let companies = try self.readSync(fetchRequest: companiesRequest) as? [Company] else {
                    completionBlock(false, Self.createError("Invalid Entity"))
                    return
                }
                
                for company in companies {
                    if let employees = company.employee {
                        for employee in employees {
                            if let employee = employee as? Person {
                                company.removeFromEmployee(employee)
                                employee.company = nil
                                try self.managedObjectContextForTask.save()
                            }
                        }
                    }
                    
                    self.managedObjectContextForTask.delete(company)
                    try self.managedObjectContextForTask.save()
                }
                
                let companiesAfterDeleted = try self.readSync(fetchRequest: companiesAfectedRequest)
                completionBlock(companiesAfterDeleted.count == 0, nil)
            } catch {
                completionBlock(false, error)
            }
        }
    }
    
    func emptyContactPersistenceStore(completionBlock: @escaping PerformTaskBlock) {
        let validationBlock: ValidationBlock = {
            resultOnPersons, resultOnCompanies in
            guard let personsHasBeenDeleted = resultOnPersons,
                let companiesHasBeenDeleted = resultOnCompanies else {
                    return
            }
            completionBlock(personsHasBeenDeleted && companiesHasBeenDeleted, nil)
        }
        
        deleteAllPersons { (result, error) in
            validationBlock(result, nil)
        }
        
        deleteAllCompanies { (result, error) in
            validationBlock(nil, result)
        }
    }
    
    func createPerson(firstName: String,
                      lastname: String,
                      email: String,
                      cellPhone: String,
                      identifier: String,
                      job: String,
                      company: Company?,
                      completionBlock: @escaping PerformTaskWithResultBlock) {
        let userExistRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        userExistRequest.predicate = NSPredicate(format: "identifier ==[cd] %@", identifier)
        
        managedObjectContextForTask.perform {
            [weak self] in
            
            guard let `self` = self else {
                completionBlock(nil, nil)
                return
            }
            
            do {
                let usersFetched = try self.readSync(fetchRequest: userExistRequest)
                if usersFetched.count > 0 {
                    completionBlock(nil, Self.createError("Person Exist"))
                    return
                }
                if let companyToSave = company, companyToSave.managedObjectContext != self.managedObjectContextForTask {
                    completionBlock(nil, Self.createError("Company belong Different MOC"))
                    return
                }
                guard let newContact = NSEntityDescription.insertNewObject(
                    forEntityName: "Person",
                    into: self.managedObjectContextForTask) as? Person else {
                        completionBlock(nil, Self.createError("Invalid Entity"))
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
                
                try newContact.validateForInsert()
                try self.managedObjectContextForTask.save()
                completionBlock(newContact, nil)
            } catch {
                completionBlock(nil, error)
            }
        }
    }
    
    func createCompany(name: String,
                       email: String,
                       address: String,
                       telephone: String?,
                       completionBlock: @escaping PerformTaskWithResultBlock) {
        let companyExistRequestValidator = NSFetchRequest<NSFetchRequestResult>(entityName: "Company")
        companyExistRequestValidator.predicate = NSPredicate(format: "identifier ==[cd] %@", name)
        
        managedObjectContextForTask.perform {
            [weak self] in
            
            guard let `self` = self else {
                completionBlock(nil, nil)
                return
            }
            
            do {
                let companyFetched = try self.readSync(fetchRequest: companyExistRequestValidator)
                if companyFetched.count > 0 {
                    completionBlock(nil, Self.createError("Company Exist"))
                    return
                }
                guard let newCompany = NSEntityDescription.insertNewObject(
                    forEntityName: "Company",
                    into: self.managedObjectContextForTask) as? Company else {
                        completionBlock(nil, Self.createError("Invalid Entity"))
                        return
                }
                
                newCompany.identifier = name
                newCompany.name = name
                newCompany.email = email
                newCompany.address = address
                newCompany.telephone = telephone
                
                try newCompany.validateForInsert()
                try self.managedObjectContextForTask.save()
                completionBlock(newCompany, nil)
            } catch {
                completionBlock(nil, error)
            }
        }
    }
    
    func delete(validationRequest: NSFetchRequest<NSFetchRequestResult>, completionBlock: @escaping PerformTaskBlock) {
        managedObjectContextForTask.perform {
            [weak self] in
            
            guard let `self` = self else {
                completionBlock(false, nil)
                return
            }
            
            do {

                let objects = try self.readSync(fetchRequest: validationRequest)
                if objects.count >= 1 {
                
                    for object in objects {
                        //Person entity(Weak entity) has a relationship with the Company entity(Strong entity)
                        if object is Person, let person = object as? Person {
                            let company = person.company
                            company?.removeFromEmployee(person)
                            person.company = nil
                            self.managedObjectContextForTask.delete(person)
                            try self.managedObjectContextForTask.save()
                            completionBlock(true, nil)
                        } else {
                            //Objects without restrictions
                            self.managedObjectContextForTask.delete(object)
                            try self.managedObjectContextForTask.save()
                            completionBlock(true, nil)
                        }
                    }

                } else {
                    completionBlock(false, Self.createError("Object not exist in Store"))
                }
                
            } catch {
                completionBlock(false, error)
            }
        }
    }
    
    
    func companyWith(_ name: String) -> Company? {
        let companyRequest = createRequestWith("Company", "identifier ==[cd] %@", [name])
        
        do {
            guard let companiesFetched = try readSync(fetchRequest: companyRequest) as? [Company] else {
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
            guard let personsFetched = try readSync(fetchRequest: personRequest) as? [Person] else {
                return nil
            }
            return personsFetched.first
        } catch {
            print("Error reading the person: \(error)")
            return nil
        }
    }
    
    //MARK: Basic Operations
    
    func readSync(fetchRequest: NSFetchRequest<NSFetchRequestResult>) throws -> [NSManagedObject] {
        let contactsFetched = try managedObjectContextForTask.fetch(fetchRequest)
        guard let contactsArray = contactsFetched as? [NSManagedObject] else {
            throw ContactsCommonErros.invalidEntity
        }
        
        return contactsArray
    }
    
    //Only for UI
    func readAsyn(fetchRequest: NSFetchRequest<NSFetchRequestResult>, completionBlock: @escaping PerformTaskWithMultipleResultBlock) {
        
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) -> Void in
            DispatchQueue.main.async {
                if let result = asynchronousFetchResult.finalResult {
                    completionBlock(result, nil)
                } else {
                    completionBlock(nil, Self.createError("Objects not founded."))
                }
            }
        }
        
        do {
            _ = try managedObjectContextForTask.execute(asynchronousFetchRequest)
        } catch {
            completionBlock(nil, error)
        }
        
    }
    
    func update(_ object: NSManagedObject, completionBlock: @escaping PerformTaskBlock) {
        managedObjectContextForTask.perform {
            [weak self] in
            
            guard let `self` = self else {
                completionBlock(false, nil)
                return
            }
            
            do {
                var objectToValidate = object
                
                if object.managedObjectContext != self.managedObjectContextForTask {
                    objectToValidate = try self.managedObjectContextForTask.existingObject(with: object.objectID)
                    
                    /**
                     NOTE: You should take care about the relationships, because some relationships
                     include sets in which the entities fetched by existingObjects probably not exists on
                     the origin object (object reference) and you should take care about this.
                     **/
                    if let personToUpdate = objectToValidate as? Person, let person = object as? Person {
                        personToUpdate.firstname = person.firstname
                        personToUpdate.lastname = person.lastname
                        personToUpdate.email = person.email
                        personToUpdate.cellphone = person.cellphone
                        personToUpdate.identifier = person.identifier
                        personToUpdate.job = person.job
                        personToUpdate.company = person.company
                    } else if let companyToUpdate = objectToValidate as? Company, let company = object as? Company {
                        /**
                         Create a custom method or extension on Company class for fetch the employees belongs on
                         the origin objecte (object reference) and fetch manually each them and add every person to
                         employees property
                         **/
                        companyToUpdate.identifier = company.name
                        companyToUpdate.name = company.name
                        companyToUpdate.email = company.email
                        companyToUpdate.address = company.address
                        companyToUpdate.telephone = company.telephone
                    } else {
                        completionBlock(false, Self.createError("Objects not belong to valid entity"))
                        return
                    }
                }
                
                try objectToValidate.validateForUpdate()
                try self.managedObjectContextForTask.save()
                completionBlock(true, nil)
            } catch {
                completionBlock(false, error)
            }
        }
    }
    
    //MARK: Utils Methods
    
    func createRequestWith(_ entityName: String, _ predicateFormat: String, _ arguments: [Any]) -> NSFetchRequest<NSFetchRequestResult> {
        let fetchedRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchedRequest.predicate = NSPredicate(format: predicateFormat, argumentArray: arguments)
        
        return fetchedRequest
    }
    
}

//MARK: Errors

extension ContactsDAO {

    static func createError(_ descriptionMessage: String) -> Error {
        let descriptionDict = [NSLocalizedDescriptionKey : descriptionMessage]
        return NSError(domain: "ContactsDAO", code: 1000, userInfo: descriptionDict)
    }
    
}
