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

class CreatePersonViewModel: NSObject, ContactsDAO {
    
    var createPersonActionListener: CreatePersonActionListener?
    private var cratePersonActionState: CreatePersonAction = .edition {
        didSet{
            createPersonActionListener?(cratePersonActionState)
        }
    }
    private var companySelected: IndexPath?

    private(set) var contactsManagedObjectContext: NSManagedObjectContext
    private(set) var companies: [Company]?
    var sections = 1
    
    init(contactsManagedObjectContext: NSManagedObjectContext) {
        self.contactsManagedObjectContext = contactsManagedObjectContext
        
        super.init()
        registerForNotification()
        fetchCompanies()
    }
    
    deinit {
        createPersonActionListener = nil
        unregisterForNotifications()
    }
    
    func fetchCompanies() {
        cratePersonActionState = .loadingCompanies

        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            do {
                self.companies = try self.allCompanies()
                self.cratePersonActionState = .companiesLoaded(error: nil)
            } catch {
                self.cratePersonActionState = .companiesLoaded(error: error.localizedDescription)
            }
        }
        
    }
    
    func createNewContact(firstname: String, lastname: String, email: String, cellPhone: String, job: String) {
        
        var companyToAdd: Company?
        if let companySelectedIndex = companySelected, let companyToAssingEmployee = company(at: companySelectedIndex){
            companyToAdd = companyToAssingEmployee
        }
        do {
            let _  = try createPerson(firstName: firstname,
                                      lastname: lastname,
                                      email: email,
                                      cellPhone: cellPhone,
                                      identifier: email,
                                      job: job,
                                      company: companyToAdd)
            cratePersonActionState = .contactCreated(error: nil)
        } catch PersonCreatingErrors.personExist {
            cratePersonActionState = .contactCreated(error: "User exits!")
        } catch {
            print("There is an error creating the new company: \(error)")
            cratePersonActionState = .contactCreated(error: "Somethig is wrong, please check the fields contain valid data")
            resetTemporallyInsertions()
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
    func company(at index: IndexPath) -> Company? {
        if index.row == 0 {
            return nil
        }
        
        let normalIndex = IndexPath(row: index.row - 1, section: index.section)
        return companies?[normalIndex.row]
    }
    
    func companyName(at: IndexPath) -> String? {
        return company(at: at)?.name
    }
    
    func numberOfItems(_ section: Int) -> Int {
        return (companies?.count ?? 0) + 1
    }
    
    //MARK: Notification Methods
    func registerForNotification() {
        let storeHasChangedSelector = #selector(CreatePersonViewModel.storeHasChanged(notification:))
        NotificationCenter.default.addObserver(self,
                                               selector: storeHasChangedSelector,
                                               name: NSNotification.Name.NSManagedObjectContextDidSave,
                                               object: nil)
    }
    
    func unregisterForNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.NSManagedObjectContextDidSave,
                                                  object: nil)
    }
    
    func storeHasChanged(notification: NSNotification) {
        guard let moc = notification.object as? NSManagedObjectContext, moc == contactsManagedObjectContext else {
            return
        }
        
        if moc.persistentStoreCoordinator != contactsManagedObjectContext.persistentStoreCoordinator {
            return
        }
        
        companies = nil
        fetchCompanies()
    }
    
}
