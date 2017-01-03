//
//  CreateCompanyViewModelTest.swift
//  Persistence_CoreData
//
//  Created by Eli Pacheco on 1/2/17.
//  Copyright © 2017 Eli Pacheco Hoyos. All rights reserved.
//

import XCTest
@testable import Persistence_CoreData

class CreateCompanyViewModelTest: XCTestCase {
    
    var viewModel: CreateCompanyViewModel!
    var contactDataStack: ContactDataStack!
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
    
    func testShouldCreateCompany() {
    
        let persistenLoadExpectation = expectation(description: "DataBaseConection")
        
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + timeToLoadData) {
            [weak self] in
            
            guard let `self` = self else {
                return
            }
            
            self.viewModel = CreateCompanyViewModel(contactsManagedObjectContext: self.contactDataStack.mainContext!)
            
            if self.viewModel.emptyContactPersistenceStore() {
                print("Data deleted!!")
            }
            
            self.viewModel.createNewCompany(name: "Atletico Nacional",
                                            address: "Cra 85 # 32 - 44",
                                            email: "nacio@verdolaga.com",
                                            telephone: "21440012")
            XCTAssert(self.viewModel.createCompanyActionState == .companyCreated(error: nil), "Company not creaded")
            
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
