//
//  ContactsFlowCoordinator.swift
//  Persistence_CoreData
//
//  Created by Eli Pacheco Hoyos on 12/19/16.
//  Copyright © 2016 Eli Pacheco Hoyos. All rights reserved.
//

import Foundation
import UIKit

struct ContactsFlowCoordinator {
    
    enum SegueIdentifiers: String {
        case createContact = "CreateContact"
        case createCompany = "CreateCompany"
    }
        
    func prepareforSegue(segue: UIStoryboardSegue) {
        guard let identifier = segue.identifier, let segueIdentifier = SegueIdentifiers(rawValue: identifier) else {
            return
        }

        switch segueIdentifier {
        case .createContact:
            prepareCreateContactView(sourceVC: segue.source, destinationVC: segue.destination)
            break
        case .createCompany:
            prepareCreateCompanyView(sourceVC: segue.source, destinationVC: segue.destination)
            break
        }
    }
    
    //MARK: Create Contact view methods
    func prepareCreateContactView(sourceVC: UIViewController, destinationVC: UIViewController) {
        guard let createContactVC = destinationVC as? CreatePersonViewController else { return }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let mainMOC = appDelegate.contactsController.mainContext else { return }
        
        let saveContext = appDelegate.contactsController.saveContext()
        let createContactVM = CreatePersonViewModel(contextForCompanies: mainMOC,
                                                    contextForCreatePerson: saveContext)
        createContactVC.createContactViewModel = createContactVM
    }
    
    func contactWasCreated(_ from: CreatePersonViewController?) {
        if let navVC = from?.navigationController {
            navVC.popViewController(animated: true)
        }
    }
    
    //MARK: Create Company view Methods
    func prepareCreateCompanyView(sourceVC: UIViewController, destinationVC: UIViewController) {
        guard let createCompanyVC = destinationVC as? CreateCompanyViewController else { return }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        let moc = appDelegate.contactsController.saveContext()
        let createCompanyVM = CreateCompanyViewModel(managedObjectContextForTask: moc)
        createCompanyVC.createCompanyViewModel = createCompanyVM
    }
    
    func companyWasCreated(_ from: CreateCompanyViewController?) {
        if let navVC = from?.navigationController {
            navVC.popViewController(animated: true)
        }
    }
    
}
