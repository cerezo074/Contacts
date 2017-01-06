//
//  ContactsDAOTest.swift
//  Persistence_CoreData
//
//  Created by Eli Pacheco Hoyos on 12/23/16.
//  Copyright © 2016 Eli Pacheco Hoyos. All rights reserved.
//

import XCTest
import CoreData
@testable import Persistence_CoreData

let testDataStore = ContactDataStack.ContactPersistentStore.name + "Test"

class ContactsDAOTest: XCTestCase {
    
    var contactDataStack: ContactDataStack!
    var contactsManager: MyContactsManager!
    var timeToSetUpDatabase = 1.0
    var timeToPerformTask = 2.0
    
    override func setUp() {
        super.setUp()
        contactDataStack = ContactDataStack(persistenStore: testDataStore)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMainContextIsValid() {
        let persistenLoadExpectation = expectation(description: "DataBaseConection")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeToSetUpDatabase) {
            [weak self] in
            
            guard let `self` = self else { return }
            XCTAssert(self.contactDataStack.mainContext != nil, "Context can't be loaded")
            persistenLoadExpectation.fulfill()
        }
        
        waitForExpectations(timeout: timeToSetUpDatabase + timeToPerformTask, handler: {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        })
    }
    
    func testDeleteAllCompanies() {
        let persistenLoadExpectation = expectation(description: "DataBaseConection")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeToSetUpDatabase) {
            [weak self] in
            
            guard let `self` = self else { return }
            self.contactsManager = MyContactsManager(managedObjectContextForTask: self.contactDataStack.mainContext!)
            
            //We create companies that are linked to persons
            let _ = self.contactsManager.createDemoPersons()
            try! self.contactsManager.managedObjectContextForTask.save()
            
            self.contactsManager.deleteAllCompanies(completionBlock: { (result, error) in
                XCTAssert(result, "Companies couldn't be deleted")
                persistenLoadExpectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: timeToSetUpDatabase + timeToPerformTask, handler: {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        })
    }
    
    func testDeleteAllPersons() {
        let persistenLoadExpectation = expectation(description: "DataBaseConection")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeToSetUpDatabase) {
            [weak self] in
            
            guard let `self` = self else { return }
            self.contactsManager = MyContactsManager(managedObjectContextForTask: self.contactDataStack.mainContext!)
            
            //We create companies that are linked to persons
            let _ = self.contactsManager.createDemoPersons()
            try! self.contactsManager.managedObjectContextForTask.save()
            
            self.contactsManager.deleteAllPersons(completionBlock: { (result, error) in
                XCTAssert(result, "Persons couldn't be deleted")
                persistenLoadExpectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: timeToSetUpDatabase + timeToPerformTask, handler: {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        })
    }
    
    func testCleanPersistenceStore() {
        let persistenLoadExpectation = expectation(description: "DataBaseConection")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeToSetUpDatabase) {
            [weak self] in
            
            guard let `self` = self else { return }
            self.contactsManager = MyContactsManager(managedObjectContextForTask: self.contactDataStack.mainContext!)
            
            self.contactsManager.emptyContactPersistenceStore {
                result, error in
                
                XCTAssert(result, "Persistence Store couldn't be cleaned")
                persistenLoadExpectation.fulfill()
            }
            
        }
        
        waitForExpectations(timeout: timeToSetUpDatabase + timeToPerformTask, handler: {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        })
    }
    
  
    //MARK: CRUD operations on Company
    
    func testDeleteCompany() {
        let persistenLoadExpectation = expectation(description: "DataBaseConection")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeToSetUpDatabase) {
            [weak self] in
            
            guard let `self` = self else { return }
            self.contactsManager = MyContactsManager(managedObjectContextForTask: self.contactDataStack.mainContext!)
            
            self.contactsManager.emptyContactPersistenceStore() {
                    result, error in
                if result {
                    //We created companies and persons based on relationships
                    let company = self.contactsManager.demoUser().company!
                    try! self.contactsManager.managedObjectContextForTask.save()
                    let deleteCompanyRequest = self.contactsManager.createRequestWith("Company", "identifier ==[cd] %@", [company.identifier!])
                    let companyName = company.name!
                    
                    self.contactsManager.delete(validationRequest: deleteCompanyRequest) {
                        result, error in
                        if result {
                            print(company)
                            XCTAssertNil(self.contactsManager.companyWith(companyName), "Company not deleted!!!")
                            persistenLoadExpectation.fulfill()
                        }
                    }
                }
            }
        }
        
        waitForExpectations(timeout: timeToSetUpDatabase + timeToPerformTask, handler: {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        })
    }

    func testUpdateCompany() {
        let persistenLoadExpectation = expectation(description: "DataBaseConection")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeToSetUpDatabase) {
            [weak self] in
            
            guard let `self` = self else { return }
            self.contactsManager = MyContactsManager(managedObjectContextForTask: self.contactDataStack.mainContext!)
            
            self.contactsManager.emptyContactPersistenceStore() {
                result, error in
                if result {
                    let companyIdentifier = "Monkey's Lab"
                    self.contactsManager.createCompany(name: companyIdentifier,
                                                       email: "medellin@monkeyslab.com",
                                                       address: "Cra 85a # 34a - 22 apto 301",
                                                       telephone: "0348273553") {
                                                        result, error in
                                                        if result != nil {
                                                            guard let companyCreated = self.contactsManager.companyWith(companyIdentifier) else { return }
                                                            let newTelephone = "0345810335"
                                                            companyCreated.telephone = newTelephone
                                                            self.contactsManager.update(companyCreated) {
                                                                result, error in
                                                                if result {
                                                                    let companyModified = self.contactsManager.companyWith(companyIdentifier)
                                                                    XCTAssert(companyModified?.telephone == newTelephone, "The company has not changed on Persistent Store")
                                                                    persistenLoadExpectation.fulfill()
                                                                }
                                                            }
                                                        }
                    }
                }
            }
        }
        
        waitForExpectations(timeout: timeToSetUpDatabase + timeToPerformTask, handler: {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        })
    }

    func testCreateCompany() {
        let persistenLoadExpectation = expectation(description: "DataBaseConection")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeToSetUpDatabase) {
            [weak self] in

            guard let `self` = self else { return }
            self.contactsManager = MyContactsManager(managedObjectContextForTask: self.contactDataStack.mainContext!)
            
            self.contactsManager.emptyContactPersistenceStore() {
                result, error in
                if result {
                    let companyIdentifier = "Monkey's Lab"
                    self.contactsManager.createCompany(name: companyIdentifier,
                                                       email: "medellin@monkeyslab.com",
                                                       address: "Cra 85a # 34a - 22 apto 301",
                                                       telephone: "0345810335") {
                                                        result, error in
                                                        if result != nil {
                                                            let companyCreated = self.contactsManager.companyWith(companyIdentifier)
                                                            XCTAssertNotNil(companyCreated, "Company not created!!!")
                                                            persistenLoadExpectation.fulfill()
                                                        }
                    }
                }
            }
        }
        
        waitForExpectations(timeout: timeToSetUpDatabase + timeToPerformTask, handler: {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        })
    }

    //MARK: CRUD Operations on Persons
    
    func testCreatePersonWithCompanyManually() {
        let persistenLoadExpectation = expectation(description: "DataBaseConection")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeToSetUpDatabase) {
            [weak self] in
            
            guard let `self` = self else { return }
            self.contactsManager = MyContactsManager(managedObjectContextForTask: self.contactDataStack.mainContext!)
            
            self.contactsManager.emptyContactPersistenceStore {
                result, error in
                if result {
                    let monekeysCompany = self.contactsManager.createMonkeysCompanyEntity()
                    self.contactsManager.createPerson(firstName: "Eli",
                                                      lastname: "Pacheco Hoyos",
                                                      email: MyContactsManager.userDefaultIdentifier,
                                                      cellPhone: "3207134723",
                                                      identifier: MyContactsManager.userDefaultIdentifier,
                                                      job: "iOS Developer",
                                                      company: monekeysCompany) {
                                                        result, error in
                                                        if result != nil {
                                                            let personCreated = self.contactsManager.personWith(MyContactsManager.userDefaultIdentifier)
                                                            XCTAssertNotNil(personCreated, "Person not created!!!")
                                                            persistenLoadExpectation.fulfill()
                                                        }
                    }
                }
            }
        }
        
        waitForExpectations(timeout: timeToSetUpDatabase + timeToPerformTask, handler: {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        })
    }

    //Person created manually and the Company created from the persisten store cordinator by a reading operation
    func testCreatePersonWithCompanyFromPersistentStore() {
        let persistenLoadExpectation = expectation(description: "DataBaseConection")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeToSetUpDatabase) {
            [weak self] in
            
            guard let `self` = self else { return }
            self.contactsManager = MyContactsManager(managedObjectContextForTask: self.contactDataStack.mainContext!)
            
            self.contactsManager.emptyContactPersistenceStore() {
                result, error in
                if result {
                    _ = self.contactsManager.createDemoPersons()
                    let monkeysCompanyReaded = self.contactsManager.companyWith(MyContactsManager.monkeysCompanyIdentifier)
                    self.contactsManager.createPerson(firstName: "Eli",
                                                      lastname: "Pacheco Hoyos",
                                                      email: MyContactsManager.userDefaultIdentifier,
                                                      cellPhone: "3207134957",
                                                      identifier: MyContactsManager.userDefaultIdentifier,
                                                      job: "iOS Developer",
                                                      company: monkeysCompanyReaded) {
                                                        result, error in
                                                        if result != nil {
                                                            let personCreated = self.contactsManager.personWith(MyContactsManager.userDefaultIdentifier)
                                                            XCTAssertNotNil(personCreated, "Person not created!!!")
                                                            persistenLoadExpectation.fulfill()
                                                        }
                    }
                }
            }
        }
        
        waitForExpectations(timeout: timeToSetUpDatabase + timeToPerformTask, handler: {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        })
    }

    func testDeletePersonWithoutCompany() {
        let persistenLoadExpectation = expectation(description: "DataBaseConection")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeToSetUpDatabase) {
            [weak self] in
            
            guard let `self` = self else { return }
            self.contactsManager = MyContactsManager(managedObjectContextForTask: self.contactDataStack.mainContext!)
            
            self.contactsManager.emptyContactPersistenceStore() {
                result, error in
                if result {
                    let personToDelete = self.contactsManager.demoUser()
                    try! self.contactsManager.managedObjectContextForTask.save()
                    let personIdentifier = personToDelete.identifier!
                    let companyIdentifier = personToDelete.company!.identifier!
                    let deleteRequest = self.contactsManager.createRequestWith("Person", "identifier ==[cd] %@", [personIdentifier])
                    self.contactsManager.delete(validationRequest: deleteRequest) {
                        result, error in
                        if result {
                            let userDeleted = self.contactsManager.personWith(personIdentifier)
                            let companyAsociated = self.contactsManager.companyWith(companyIdentifier)
                            XCTAssert(userDeleted == nil && companyAsociated != nil, "Person was deleted without the company!!!")
                            persistenLoadExpectation.fulfill()
                        }
                    }
                }
            }
        }
        
        waitForExpectations(timeout: timeToSetUpDatabase + timeToPerformTask, handler: {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        })
    }

    func testUpdatePerson() {
        let persistenLoadExpectation = expectation(description: "DataBaseConection")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeToSetUpDatabase) {
            [weak self] in
            
            guard let `self` = self else { return }
            self.contactsManager = MyContactsManager(managedObjectContextForTask: self.contactDataStack.mainContext!)
            
            self.contactsManager.emptyContactPersistenceStore() {
                result, error in
                if result {
                    let person = self.contactsManager.demoUser()
                    try! self.contactsManager.managedObjectContextForTask.save()
                    let lionsCompany = self.contactsManager.companyWith(MyContactsManager.lionsCompanyIdentifier)
                    person.company = lionsCompany
                    self.contactsManager.update(person) {
                        result, error in
                        if result {
                            let personUpdated = self.contactsManager.personWith(person.identifier!)
                            XCTAssert(personUpdated!.company!.identifier == lionsCompany!.identifier, "Person wasn't updated!!!")
                            persistenLoadExpectation.fulfill()
                        }
                    }
                }
            }
        }
        
        waitForExpectations(timeout: timeToSetUpDatabase + timeToPerformTask, handler: {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        })
    }

}

class MyContactsManager: NSObject, ContactsDAO {

    static let monkeysCompanyIdentifier = "Monkey's Lab"
    static let lionsCompanyIdentifier = "Lion's Lab"
    static let userDefaultIdentifier = "eph_074@hotmail.com"
    var managedObjectContextForTask: NSManagedObjectContext
    
    init(managedObjectContextForTask: NSManagedObjectContext) {
        self.managedObjectContextForTask = managedObjectContextForTask
    }
    
    func createMonkeysCompanyEntity() -> Company {
        let monkeys = NSEntityDescription.insertNewObject(
            forEntityName: "Company",
            into: managedObjectContextForTask) as! Company
        
        monkeys.name = MyContactsManager.monkeysCompanyIdentifier
        monkeys.email = "medellin@monkeyslab.com"
        monkeys.address = "Cra 85a # 34a - 22 apto 301"
        monkeys.telephone = "0345810335"
        monkeys.identifier = MyContactsManager.monkeysCompanyIdentifier
        
        return monkeys
    }
    
    func createDemoCompanies() -> [Company] {
    
        let monkeys = createMonkeysCompanyEntity()
        let lions = NSEntityDescription.insertNewObject(
            forEntityName: "Company",
            into: managedObjectContextForTask) as! Company
        
        lions.name = MyContactsManager.lionsCompanyIdentifier
        lions.email = "medellin@lionslab.com"
        lions.address = "Cra 85a # 34a - 22 apto 302"
        lions.telephone = "0345810336"
        lions.identifier = MyContactsManager.lionsCompanyIdentifier
        
        return [monkeys, lions]
    }
    
    func createDemoPersons() -> [Person] {
    
        let companies = createDemoCompanies()
        let monkeys = companies[0]
        let lions = companies[1]
        
        let jaime = NSEntityDescription.insertNewObject(
            forEntityName: "Person",
            into: managedObjectContextForTask) as! Person
        
        jaime.firstname = "Jaime"
        jaime.lastname = "Perez Cordoba"
        jaime.email = "jaimito@abc.com"
        jaime.cellphone = "3201234567"
        jaime.identifier = "jaimito@abc.com"
        jaime.job = "Net Developer"
        jaime.company = monkeys
        monkeys.addToEmployee(jaime)
        
        let juan = NSEntityDescription.insertNewObject(
            forEntityName: "Person",
            into: managedObjectContextForTask) as! Person
        
        juan.firstname = "Juan"
        juan.lastname = "Pacheco Ramirez"
        juan.email = "juancho@abc.com"
        juan.cellphone = "3201234569"
        juan.identifier = "juancho@abc.com"
        juan.job = "Android Developer"
        juan.company = monkeys
        monkeys.addToEmployee(juan)
        
        let pedro = NSEntityDescription.insertNewObject(
            forEntityName: "Person",
            into: managedObjectContextForTask) as! Person
        
        pedro.firstname = "pedro"
        pedro.lastname = "Picapiedra De la Roca"
        pedro.email = "pedrito@abc.com"
        pedro.cellphone = "3201234512"
        pedro.identifier = "pedrito@abc.com"
        pedro.job = "Java Developer"
        pedro.company = lions
        lions.addToEmployee(pedro)
        
        return [jaime, juan, pedro]
    }
    
    func demoUser() -> Person {
        return createDemoPersons().first!
    }
    
}
