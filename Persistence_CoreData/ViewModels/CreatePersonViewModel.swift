//
//  CreatePersonViewModel.swift
//  Persistence_CoreData
//
//  Created by Eli Pacheco Hoyos on 12/19/16.
//  Copyright © 2016 Eli Pacheco Hoyos. All rights reserved.
//

import Foundation
import CoreData

struct CreatePersonViewModel: ContactsDAO {
    var contactsManagedObjectContext: NSManagedObjectContext
    
    init(contactsManagedObjectContext: NSManagedObjectContext) {
        self.contactsManagedObjectContext = contactsManagedObjectContext
    }
    
    func saveDemoObject() {
        
        guard let monkeysLab = NSEntityDescription.insertNewObject(forEntityName: "Company",
                                                                   into: contactsManagedObjectContext) as? Company else {
                                                                    return
        }
        monkeysLab.name = "Monkey's Lab"
        monkeysLab.email = "medellin@monkeyslab.com"
        monkeysLab.address = "Cra 85a # 34a - 22 apto 301"
        monkeysLab.gps = "105.222,3322.110"
        monkeysLab.identifier = "medellin@monkeyslab.com"
        
        do {
            try createPerson(firstName: "Eli",
                             lastname: "Pacheco Hoyos",
                             email: "eph_074@hotmail.com",
                             cellPhone: "3207134957",
                             identifier: "eph_074@hotmail.com",
                             job: "iOS Developer",
                             company: monkeysLab)
            print("Demo user created!")
        } catch {
            print("Error creating demo user: \(error)")
        }
    }
}
