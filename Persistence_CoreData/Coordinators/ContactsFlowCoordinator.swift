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
        case CreateContact = "CreateContact"
        case UpdateContact = "UpdateContact"
    }
        
    func prepareforSegue(segue: UIStoryboardSegue) {
        guard let identifier = segue.identifier, let segueIdentifier = SegueIdentifiers(rawValue: identifier) else { return }

        switch segueIdentifier {
        case .CreateContact:
            prepareCreateContactView(sourceVC: segue.source,
                                     destinationVC: segue.destination)
            break
        case .UpdateContact:
            break
        }
    }
    
    func prepareCreateContactView(sourceVC: UIViewController, destinationVC: UIViewController) {
        guard let createContactVC = destinationVC as? CreatePersonViewController else { return }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let moc = appDelegate.contactsController.managedObjectContext else { return }
        
        let createContactVM = CreatePersonViewModel(contactsManagedObjectContext: moc)
        createContactVC.createContactViewModel = createContactVM
    }
    
}
