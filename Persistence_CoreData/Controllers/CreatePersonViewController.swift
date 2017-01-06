//
//  CreatePersonViewController.swift
//  Persistence_CoreData
//
//  Created by Eli Pacheco Hoyos on 12/19/16.
//  Copyright © 2016 Eli Pacheco Hoyos. All rights reserved.
//

import UIKit
import CoreData

class CreatePersonViewController: FormController {

    @IBOutlet weak var firstnameTextField: UITextField!
    @IBOutlet weak var lastnameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var jobTextField: UITextField!
    @IBOutlet weak var cellPhoneTextField: UITextField!
    @IBOutlet weak var companyTextField: PickerTextField!
    @IBOutlet weak var saveButton: UIButton!
    
    var createContactViewModel: CreatePersonViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        companyTextField.setDelegates(delegate: self,
                                      datasource: self,
                                      toolbarDelegate: self)
        bindActionListener()
        
        firstnameTextField.text = "Radamel"
        lastnameTextField.text = "Falcao Garcia"
        emailTextField.text = "falcao@eltigre.com"
        jobTextField.text = "Delantero AS Monaco"
        cellPhoneTextField.text = "3201234567"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func inputViews() -> [UIView]? {
        return [
            firstnameTextField,
            lastnameTextField,
            emailTextField,
            jobTextField,
            cellPhoneTextField,
            companyTextField
        ]
    }
    
    func bindActionListener() {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        createContactViewModel.createPersonActionListener = {
            [weak self, weak appDelegate] state in
            switch state {
            case .contactCreated(let error):
                guard let message = error else {
                    appDelegate?.contactsFlowCoordinator.contactWasCreated(self)
                    return
                }
                self?.showResultActionMessage("Create Contact", message)
                break
            case .companiesLoaded(let error):
                if let message = error {
                    print("Error loading companies: \(message)")
                }
                
                self?.companyTextField.isEnabled = error == nil ? true : false
                
                if error == nil && self?.companyTextField == self?.firstResponder() {
                    self?.companyTextField.reload()
                }
                break
            case .loadingCompanies:
                self?.companyTextField.isEnabled = false
                break
            default:
                break
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.contactsFlowCoordinator.prepareforSegue(segue: segue)
    }
    
    //MARK: IBAction Methods
    
    @IBAction func saveButtonIsPressed(_ sender: Any) {
        
        guard let firstname = firstnameTextField.text,
            let lastname = lastnameTextField.text,
            let email = emailTextField.text,
            let cellPhone = cellPhoneTextField.text,
            let job = cellPhoneTextField.text else {
                showResultActionMessage("Create Contact", "Please you must fill all fields, the only field allowed to" +
                    "be empty is Company for independent persons.")
                return
        }
        
        createContactViewModel.createNewContact(firstname: firstname,
                                                lastname: lastname,
                                                email: email,
                                                cellPhone: cellPhone,
                                                job: job)
    }

}

extension CreatePersonViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

extension CreatePersonViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        var companies = createContactViewModel.numberOfItems(component)
        //Introduce the default company
        companies = companies == 0 ? 1 : companies
        return companies
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let indexPath = IndexPath(row: row, section: component)
        return createContactViewModel.companyName(at: indexPath) ?? createContactViewModel.indepentCompanyName
    }
    
}

extension CreatePersonViewController: PickerTextToolbarDelegate {

    func doneTitle() -> String {
        return "Done"
    }
    
    func cancelTitle() -> String {
        return "Cancel"
    }
    
    func tintColor() -> UIColor {
        return UIColor.blue
    }
    
    func doneButtonPressed(button: UIBarButtonItem) {
        companyTextField.resignFirstResponder()
        let component = 0
        if let rowSelected = companyTextField.pickerView?.selectedRow(inComponent: component) {
            createContactViewModel.selectCompany(IndexPath(row: rowSelected, section: component))
            let indexPath = IndexPath(row: rowSelected, section: component)
            companyTextField.text = createContactViewModel.companyName(at: indexPath) ?? createContactViewModel.indepentCompanyName
        }
    }
    
    func cancelButtonPressed(cancel: UIBarButtonItem) {
        companyTextField.resignFirstResponder()
        createContactViewModel.deselectCompany()
        companyTextField.text = ""
    }
    
}
