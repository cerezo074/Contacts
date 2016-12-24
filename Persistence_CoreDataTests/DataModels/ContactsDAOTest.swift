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
    var timeToLoadData = 1.5
    var timeToPerformTask = 2.0
    
    override func setUp() {
        super.setUp()
        contactDataStack = ContactDataStack(persistenStore: testDataStore)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCleanPersistenceStore() {
    
        let persistenLoadExpectation = expectation(description: "DataBaseConection")
        
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + timeToLoadData) {
            [weak self] in
            
            guard let `self` = self else {
                return
            }
            
            self.contactsManager = MyContactsManager(contactsManagedObjectContext: self.contactDataStack.managedObjectContext!)
            XCTAssert(self.contactsManager.emptyContactPersistenceStore(), "Persistence Store couldn't be cleaned")
            
            persistenLoadExpectation.fulfill()
        }
        
        waitForExpectations(timeout: timeToLoadData + timeToPerformTask, handler: {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        })
        
    }
    
    func testDeleteCompany() {
    
        let persistenLoadExpectation = expectation(description: "DataBaseConection")
        
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + timeToLoadData) {
            [weak self] in
            
            guard let `self` = self else {
                return
            }
            
            self.contactsManager = MyContactsManager(contactsManagedObjectContext: self.contactDataStack.managedObjectContext!)
            
            if self.contactsManager.emptyContactPersistenceStore() {
                print("Data deleted!!")
            }
            
            let companyIdentifier = "Monkey's Lab"
            let _ = try! self.contactsManager.createCompany(name: companyIdentifier,
                                                            email: "medellin@monkeyslab.com",
                                                            address: "Cra 85a # 34a - 22 apto 301",
                                                            telephone: "0345810335")
            let request = self.contactsManager.createRequestWith("Company", "identifier ==[cd] %@", [companyIdentifier])
            let result = try! self.contactsManager.delete(validationRequest: request)
            XCTAssert(result, "Company not deleted!!!")
            
            persistenLoadExpectation.fulfill()
        }
        
        waitForExpectations(timeout: timeToLoadData + timeToPerformTask, handler: {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        })
        
    }
    
    func testUpdateCompany() {
    
        let persistenLoadExpectation = expectation(description: "DataBaseConection")
        
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + timeToLoadData) {
            [weak self] in
            
            guard let `self` = self else {
                return
            }
            
            self.contactsManager = MyContactsManager(contactsManagedObjectContext: self.contactDataStack.managedObjectContext!)
            
            if self.contactsManager.emptyContactPersistenceStore() {
                print("Data deleted!!")
            }
            
            let companyIdentifier = "Monkey's Lab"
            let _ = try! self.contactsManager.createCompany(name: companyIdentifier,
                                                            email: "medellin@monkeyslab.com",
                                                            address: "Cra 85a # 34a - 22 apto 301",
                                                            telephone: "0348273553")
            
            let companyCreated = self.contactsManager.companyWith(companyIdentifier)
            let newTelephone = "0345810335"
            companyCreated?.telephone = newTelephone
            try! self.contactsManager.update(companyCreated!)
            
            let companyModified = self.contactsManager.companyWith(companyIdentifier)
            XCTAssert(companyModified?.telephone == newTelephone, "The company has not changed on Persistent Store")
            
            persistenLoadExpectation.fulfill()
        }
        
        waitForExpectations(timeout: timeToLoadData + timeToPerformTask, handler: {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        })
        
    }
    
    func testCreateCompany() {
        
        let persistenLoadExpectation = expectation(description: "DataBaseConection")

        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + timeToLoadData) {
            [weak self] in

            guard let `self` = self else {
                return
            }
            
            self.contactsManager = MyContactsManager(contactsManagedObjectContext: self.contactDataStack.managedObjectContext!)
            
            if self.contactsManager.emptyContactPersistenceStore() {
                print("Data deleted!!")
            }

            let companyIdentifier = "Monkey's Lab"
            let _ = try! self.contactsManager.createCompany(name: companyIdentifier,
                                                       email: "medellin@monkeyslab.com",
                                                       address: "Cra 85a # 34a - 22 apto 301",
                                                       telephone: "0345810335")
            
            let companyCreated = self.contactsManager.companyWith(companyIdentifier)
            XCTAssertNotNil(companyCreated, "Company not created!!!")
            
            persistenLoadExpectation.fulfill()
        }
        
        waitForExpectations(timeout: timeToLoadData + timeToPerformTask, handler: {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        })

    }
    
}

struct MyContactsManager: ContactsDAO {

    var contactsManagedObjectContext: NSManagedObjectContext
    
    init(contactsManagedObjectContext: NSManagedObjectContext) {
        self.contactsManagedObjectContext = contactsManagedObjectContext
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
    
    func createRequestWith(_ entityName: String, _ predicateFormat: String, _ arguments: [Any]) -> NSFetchRequest<NSFetchRequestResult> {
        let fetchedRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchedRequest.predicate = NSPredicate(format: predicateFormat, argumentArray: arguments)
        
        return fetchedRequest
    }
    
}
