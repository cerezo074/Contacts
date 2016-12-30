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
    var companiesListener: CompanyListener?
    private var companySelected: IndexPath?

    private(set) var contactsManagedObjectContext: NSManagedObjectContext
    private(set) var companiesFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    var sections: Int {
        return companiesFetchedResultsController?.sections?.count ?? 0
    }
    
    init(contactsManagedObjectContext: NSManagedObjectContext) {
        self.contactsManagedObjectContext = contactsManagedObjectContext
    }
    
    func setUpCompanies() {
        let fetchAllCompaniesRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Company")
        fetchAllCompaniesRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        companiesFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchAllCompaniesRequest,
                                                                       managedObjectContext: contactsManagedObjectContext,
                                                                       sectionNameKeyPath: nil,
                                                                       cacheName: nil)
        companiesFetchedResultsController?.delegate = self
        cratePersonActionState = .loadingCompanies
        
        do {
            try companiesFetchedResultsController?.performFetch()
            cratePersonActionState = .companiesLoaded(error: nil)
        } catch {
            print("Error loading the companies: \(error)")
            cratePersonActionState = .companiesLoaded(error: "The companies couldn't be loaded, please try again")
        }
    }
    
    func createNewContact(firstname: String, lastname: String, email: String, cellPhone: String, job: String) {
        
        var company: Company?
        if let companySelectedIndex = companySelected, let companyToAssingEmployee = companyAt(companySelectedIndex) {
            company = companyToAssingEmployee
        }
        do {
            let _  = try createPerson(firstName: firstname,
                                      lastname: lastname,
                                      email: email,
                                      cellPhone: cellPhone,
                                      identifier: email,
                                      job: job,
                                      company: company)
            cratePersonActionState = .contactCreated(error: nil)
        } catch PersonCreatingErrors.personExist {
            cratePersonActionState = .contactCreated(error: "User exits!")
        } catch {
            print("There is an error creating the new company: \(error)")
            cratePersonActionState = .contactCreated(error: "Somethig was wrong, please check the fields contain valid data")
        }
    }
    
    func selectCompany(_ at: IndexPath) {
        if at.row > 0 {
            companySelected = at
        }
    }
    
}

extension CreatePersonViewModel: NSFetchedResultsControllerDelegate {
    
    //Check the increment for the indexpath based by the indepent company, the row if offset by 1
    
    func companyAt(_ index: IndexPath) -> Company? {
        if index.row == 0 {
            return nil
        }
        
        let normalIndex = IndexPath(row: index.row - 1, section: index.section)
        return companiesFetchedResultsController?.object(at: normalIndex) as? Company
    }
    
    func numberOfItems(_ section: Int) -> Int {
        return (companiesFetchedResultsController?.sections?[section].numberOfObjects ?? 0) + 1
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .delete, .insert, .update:
            companiesListener?()
            break
        case .move:
            break
        }
    }
}
