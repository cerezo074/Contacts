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

class CreateCompanyViewModel: ContactsDAO {
    
    enum CreateCompanyAction: Equatable {
        case editing
        case companyCreated(error: String?)
    }
    
    var managedObjectContextForTask: NSManagedObjectContext
    var createCompanyListener: CreateCompanyActionsListener?
    private(set) var createCompanyActionState: CreateCompanyAction = .editing {
        didSet {
            createCompanyListener?(createCompanyActionState)
        }
    }
    
    init(managedObjectContextForTask: NSManagedObjectContext) {
        self.managedObjectContextForTask = managedObjectContextForTask
    }
    
    func createNewCompany(name: String, address: String, email: String, telephone: String?) {
        createCompany(name: name, email: email, address: address, telephone: telephone) {
            [weak self] result, error in
            if result != nil && error == nil {
                self?.createCompanyActionState = .companyCreated(error: nil)
            } else {
                self?.createCompanyActionState = .companyCreated(error: error?.localizedDescription)
            }
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
