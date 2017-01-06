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

class CreatePersonViewModel: NSObject, ContactsDAO {
    
    var createPersonActionListener: CreatePersonActionListener?
    var cratePersonActionState: CreatePersonAction = .edition {
        didSet{
            createPersonActionListener?(cratePersonActionState)
        }
    }
    private(set) var managedObjectContextForTask: NSManagedObjectContext
    private(set) var contextForCompanies: NSManagedObjectContext
    private(set) var companiesFetchResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    private var companySelected: IndexPath?
    var sections = 1
    var indepentCompanyName = "Indepent"
    
    init(contextForCompanies: NSManagedObjectContext, contextForCreatePerson: NSManagedObjectContext) {
        self.managedObjectContextForTask = contextForCreatePerson
        self.contextForCompanies = contextForCompanies
        
        super.init()
        fetchCompanies()
    }
    
    deinit {
        createPersonActionListener = nil
    }
    
    func fetchCompanies() {
        cratePersonActionState = .loadingCompanies
        let companiesFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Company")
        companiesFetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        self.companiesFetchResultsController = NSFetchedResultsController(
            fetchRequest: companiesFetchRequest,
            managedObjectContext: contextForCompanies,
            sectionNameKeyPath: nil,
            cacheName: nil)
        self.companiesFetchResultsController?.delegate = self
        
        do {
            try self.companiesFetchResultsController?.performFetch()
            self.cratePersonActionState = .companiesLoaded(error: nil)
        } catch {
            print("Error loading companies, error: \(error)")
            self.cratePersonActionState = .companiesLoaded(error: error.localizedDescription)
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
                                //NOTE: transform the error in case that error was triggered by validating the scheme
                                print("Error creating the person, error:\(error)")
                                self?.resetTemporallyInsertions()
                                self?.cratePersonActionState = .contactCreated(error:"Sorry but there was an error, you should use valid data on fields!.")
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

}

extension CreatePersonViewModel: NSFetchedResultsControllerDelegate {

    //Check the increment for the indexpath based by the indepent company, the row if offset by 1
    func company(_ index: IndexPath) -> Company? {
        if index.row == 0 {
            return nil
        }
        
        let normalIndex = IndexPath(row: index.row - 1, section: index.section)
        return companiesFetchResultsController?.object(at: normalIndex) as? Company
    }
    
    func companyName(at: IndexPath) -> String? {
        return company(at)?.name
    }
    
    func numberOfItems(_ section: Int) -> Int {
        return (companiesFetchResultsController?.sections?[section].numberOfObjects ?? 0) + 1
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete, .insert, .update:
            cratePersonActionState = .companiesLoaded(error: nil)
        default:
            break
        }
    }
    
}
