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
            let moc = appDelegate.contactsController.saveContext() else { return }
        
        let createContactVM = CreatePersonViewModel(contactsManagedObjectContext: moc)
        createContactVC.createContactViewModel = createContactVM
    }
    
    func contactWasCreated(_ from: CreatePersonViewController?) {
        if let navVC = from?.navigationController {
            navVC.popViewController(animated: true)
        }
    }
    
    //MARK: Create Company view Methods
    func prepareCreateCompanyView(sourceVC: UIViewController, destinationVC: UIViewController) {
        guard let createContactVC = sourceVC as? CreatePersonViewController else { return }
        guard let createCompanyVC = destinationVC as? CreateCompanyViewController else { return }
        
        let moc = createContactVC.createContactViewModel.contactsManagedObjectContext
        let createCompanyVM = CreateCompanyViewModel(contactsManagedObjectContext: moc)
        createCompanyVC.createCompanyViewModel = createCompanyVM
    }
    
    func companyWasCreated(_ from: CreateCompanyViewController?) {
        if let navVC = from?.navigationController {
            navVC.popViewController(animated: true)
        }
    }
    
}
