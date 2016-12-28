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
    case createCompany
    case loadingCompanies
    case companiesLoaded(errorMessage: String?)
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
    var companySelected: IndexPath?

    private(set) var contactsManagedObjectContext: NSManagedObjectContext
    private(set) var companiesFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>
    var sections: Int {
        return companiesFetchedResultsController.sections?.count ?? 0
    }
    
    init(contactsManagedObjectContext: NSManagedObjectContext) {

        self.contactsManagedObjectContext = contactsManagedObjectContext

        let fetchAllCompaniesRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Company")
        fetchAllCompaniesRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        companiesFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchAllCompaniesRequest,
                                                                       managedObjectContext: contactsManagedObjectContext,
                                                                       sectionNameKeyPath: nil,
                                                                       cacheName: nil)
        super.init()
        companiesFetchedResultsController.delegate = self
        cratePersonActionState = .loadingCompanies
        
        do {
            try companiesFetchedResultsController.performFetch()
            cratePersonActionState = .companiesLoaded(errorMessage: nil)
        } catch {
            print("Error loading the companies: \(error)")
            cratePersonActionState = .companiesLoaded(errorMessage: "The companies couldn't be loaded, please try again")
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
        } catch {
            print("There is an error creating the new company: \(error)")
            cratePersonActionState = .contactCreated(error: "Somethig was wrong, please check the fields contain valid data")
        }
    }
    
}

extension CreatePersonViewModel: NSFetchedResultsControllerDelegate {
    
    func companyAt(_ index: IndexPath) -> Company? {
        return companiesFetchedResultsController.object(at: index) as? Company
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
