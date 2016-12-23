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
    
    let contactDataStack = ContactDataStack(persistenStore: testDataStore)
    var contactsManager: MyContactsManager? = nil
    
    override func setUp() {
        super.setUp()
        var _ = contactDataStack.emptyContactPersistenceStore()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreateCompany() {
    
    }
    
}

struct MyContactsManager: ContactsDAO {

    var contactsManagedObjectContext: NSManagedObjectContext
    
    init(contactsManagedObjectContext: NSManagedObjectContext) {
        self.contactsManagedObjectContext = contactsManagedObjectContext
    }
    
}
