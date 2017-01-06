//
//  CreatePersonViewModel.swift
//  Persistence_CoreData
//
//  Created by Eli Pacheco Hoyos on 12/19/16.
//  Copyright © 2016 Eli Pacheco Hoyos. All rights reserved.
//

import Foundation
import CoreData

enum CreatePersonAction {
    case edition
    case contactCreated(error: String?)
    case loadingCompanies
    case companiesLoaded(error: String?)
}

typealias CreatePersonActionListener = (_ state: CreatePersonAction) -> Void
typealias CompanyListener = () -> Void

class CreatePersonViewModel: NSObject, ContactsDAO, ContextHasChangedProtocol {
    
    var createPersonActionListener: CreatePersonActionListener?
    private var cratePersonActionState: CreatePersonAction = .edition {
        didSet{
            createPersonActionListener?(cratePersonActionState)
        }
    }
    private var companySelected: IndexPath?

    private(set) var managedObjectContextForTask: NSManagedObjectContext
    private(set) var companies: [Company]?
    var sections = 1
    var indepentCompanyName = "Indepent"
    
    init(managedObjectContextForTask: NSManagedObjectContext) {
        self.managedObjectContextForTask = managedObjectContextForTask
        
        super.init()
        registerForDidSaveNotification(obj: self)
        fetchCompanies()
    }
    
    deinit {
        createPersonActionListener = nil
        unregisterForDidSaveNotification(obj: self)
    }
    
    func fetchCompanies() {
        cratePersonActionState = .loadingCompanies
        self.allCompanies { [weak self] (result, error) in
            guard let companies = result as? [Company] else {
                self?.cratePersonActionState = .companiesLoaded(error: error?.localizedDescription)
                return
            }
            
            self?.companies = companies
            self?.cratePersonActionState = .companiesLoaded(error: nil)
        }
    }
    
    func createNewContact(firstname: String, lastname: String, email: String, cellPhone: String, job: String) {
        
        var companyToAdd: Company?
        
        if let companySelectedIndex = companySelected, let companyToAssingEmployee = company(companySelectedIndex) {
            companyToAdd = companyToAssingEmployee
        }
        
        do {
            createPerson(firstName: firstname,
                         lastname: lastname,
                         email: email,
                         cellPhone: cellPhone,
                         identifier: email,
                         job: job,
                         company: companyToAdd) {
                            [weak self] result, error in
                            if result != nil && error == nil {
                                self?.cratePersonActionState = .contactCreated(error: nil)
                            } else {
                                self?.cratePersonActionState = .contactCreated(error: error?.localizedDescription)
                            }
            }
        }
    }
    
    func selectCompany(_ at: IndexPath) {
        if at.row > 0 {
            companySelected = at
        }
    }
    
    func deselectCompany() {
        companySelected = nil
    }
    
    //Check the increment for the indexpath based by the indepent company, the row if offset by 1
    func company(_ index: IndexPath) -> Company? {
        if index.row == 0 {
            return nil
        }
        
        let normalIndex = IndexPath(row: index.row - 1, section: index.section)
        return companies?[normalIndex.row]
    }
    
    func companyName(at: IndexPath) -> String? {
        return company(at)?.name
    }
    
    func numberOfItems(_ section: Int) -> Int {
        return (companies?.count ?? 0) + 1
    }
    
    //MARK: Notification Methods
    
        func storeShouldChange(notification: Notification) {
            guard let moc = notification.object as? NSManagedObjectContext, moc == managedObjectContextForTask else {
            return
        }
        
        if moc.persistentStoreCoordinator != managedObjectContextForTask.persistentStoreCoordinator {
            return
        }
        
        companies = nil
        fetchCompanies()
    }
    
}
