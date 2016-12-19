//
//  ContactsViewController.swift
//  Persistence_CoreData
//
//  Created by Eli Pacheco Hoyos on 12/19/16.
//  Copyright © 2016 Eli Pacheco Hoyos. All rights reserved.
//

import UIKit

class ContactsViewController: UIViewController {

    @IBOutlet weak var contactsTableView: UITableView!
    @IBOutlet weak var messageLabel: UILabel!
    
    var contactsViewModel: ContactsViewModel!
    var contactsFlowCoordinator: ContactsFlowCoordinator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //This initialization are inyected from other controller when prepare segue is called "NORMALLY"
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        contactsViewModel = ContactsViewModel(contactsController: appDelegate.contactsController)
        contactsFlowCoordinator = ContactsFlowCoordinator()
        
        bindDataState()
        bindUserActionsOnDataState()
        showMessageLabel(message: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func bindDataState() {
        contactsViewModel.dataListener = {
            [weak self] dataState in
            switch dataState {
            case .Fetching:
                self?.showMessageLabel(message: "Data is loading, please wait... ;)")
                break
            case .Iddle:
                break
            case .Loaded(let error):
                self?.showMessageLabel(message: error)
                self?.contactsTableView.reloadData()
                break
            }
        }
    }
    
    func bindUserActionsOnDataState() {
        contactsViewModel.userActionOnDataListener = {
            [weak self] userActionOnData in
            switch userActionOnData {
            case .delete(let indexPath):
                break
            case .insert(let indexPath):
                break
            case .update(let indexPath):
                break
            case .Iddle:
                break
            }
        }
    }
    
    func showMessageLabel(message: String?) {
        let hideContactsTableView = message == nil ? false : true
        contactsTableView.isUserInteractionEnabled = !hideContactsTableView
        contactsTableView.isHidden = hideContactsTableView
        messageLabel.isHidden = !hideContactsTableView
        messageLabel.text = message
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        contactsFlowCoordinator.prepareforSegue(segue: segue)
    }

}

extension ContactsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return contactsViewModel.sections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactsViewModel.numbersOfContactsForSection(section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ??
            UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: reuseIdentifier)
        
        guard let contact = contactsViewModel.contactAtIndex(indexPath) else {
            return UITableViewCell()
        }

        configureCellWithContact(contact: contact, cell)
        cell.detailTextLabel?.textColor = UIColor.gray
        
        return cell
    }
    
    func configureCellWithContact(contact: Person, _ cell: UITableViewCell) {
        cell.textLabel?.text = contactsViewModel.titleInfo(contact: contact)
        cell.detailTextLabel?.text = contactsViewModel.contactSubtitleInfo(contact: contact)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
