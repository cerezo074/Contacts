//
//  CreateCompanyViewModel.swift
//  Persistence_CoreData
//
//  Created by Eli Pacheco Hoyos on 12/22/16.
//  Copyright © 2016 Eli Pacheco Hoyos. All rights reserved.
//

import Foundation
import CoreData

typealias CreateCompanyActionsListener = (_ state: CreateCompanyViewModel.CreateCompanyAction) -> Void

struct CreateCompanyViewModel: ContactsDAO {
    
    enum CreateCompanyAction: Equatable {
        case editing
        case companyCreated(error: String?)
    }
    
    var contactsManagedObjectContext: NSManagedObjectContext
    var createCompanyListener: CreateCompanyActionsListener?
    private(set) var createCompanyActionState: CreateCompanyAction = .editing {
        didSet {
            createCompanyListener?(createCompanyActionState)
        }
    }
    
    init(contactsManagedObjectContext: NSManagedObjectContext) {
        self.contactsManagedObjectContext = contactsManagedObjectContext
    }
    
    mutating func createNewCompany(name: String, address: String, email: String, telephone: String?) {
        do {
            let _ = try createCompany(name: name, email: email, address: address, telephone: telephone)
            createCompanyActionState = .companyCreated(error: nil)
        } catch CompanyCreatingErrors.companyExist {
            createCompanyActionState = .companyCreated(error: "Company Exists!.")
        } catch {
            createCompanyActionState = .companyCreated(error: "Somethig is wrong, please check the fields contain valid data")
            resetTemporallyInsertions()
        }
    }
    
}

func ==(lhs: CreateCompanyViewModel.CreateCompanyAction, rhs: CreateCompanyViewModel.CreateCompanyAction) -> Bool {
    switch (lhs, rhs) {
    case (let .companyCreated(error), let .companyCreated(error2)):
        return error == error2
    case (.editing , .editing):
        return true
    default:
        return false
    }
}
