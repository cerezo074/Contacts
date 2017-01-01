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
        
        let tapOnFormScrollSelector = #selector(CreatePersonViewController.formScrollViewWasTapped(gesture:))
        let tapGestureOnFormScroll = UITapGestureRecognizer(target: self, action: tapOnFormScrollSelector)
        formScrollView.addGestureRecognizer(tapGestureOnFormScroll)
        
        companyTextField.pickerToolbarActionDelegate = self
        companyTextField.pickerViewDataSource = self
        companyTextField.pickerViewDelegate = self
        
        bindActionListener()
        bindCompanySelected()
        createContactViewModel.setUpCompanies()
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
        createContactViewModel.createPersonActionListener = {
            [weak self] state in
            switch state {
            case .contactCreated(let error):
                guard let message = error else {
                    //Call coordinator handler
                    if let navVC = self?.navigationController {
                        navVC.popViewController(animated: true)
                    }
                    return
                }
                self?.showResultActionMessage("Create Contact", message)
                break
            case .companiesLoaded(let error):
                if let message = error {
                    print("Error loading companies: \(message)")
                }
                self?.companyTextField.isEnabled = error == nil ? true : false
                break
            case .loadingCompanies:
                self?.companyTextField.isEnabled = false
                break
            default:
                break
            }
        }
    }
    
    func bindCompanySelected() {
        createContactViewModel.companiesListener = {
            [weak self] in
            if self?.companyTextField == self?.firstResponder() {
                self?.companyTextField.reload()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Call Coordinator
    }
    
    //MARK: IBAction Methods
    
    @IBAction func saveButtonIsPressed(_ sender: Any) {
        
        guard let firstname = firstnameTextField.text,
            let lastname = lastnameTextField.text,
            let email = emailTextField.text,
            let cellPhone = cellPhoneTextField.text,
            let job = cellPhoneTextField.text else {
                showResultActionMessage("Create Contact", "Please you must fill all fields, the only field allowed to be empty is Company for independent persons.")
                return
        }
        
        createContactViewModel.createNewContact(firstname: firstname,
                                                lastname: lastname,
                                                email: email,
                                                cellPhone: cellPhone,
                                                job: job)
    }
    
    //MARK: Gesture Recognizers Methods
    
    func formScrollViewWasTapped(gesture: UITapGestureRecognizer) {
        formScrollView.endEditing(true)
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
        let company = createContactViewModel.companyAt(indexPath)
        return company?.name ?? indepentCompanyName
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        createContactViewModel.selectCompany(IndexPath(row: row, section: component))
        companyTextField.text = self.pickerView(pickerView, titleForRow: row, forComponent: component)
    }
    
}

extension CreatePersonViewController: PicketTextFieldActionProtocol {

    func doneTitle() -> String {
        return "Done"
    }
    
    func cancelTitle() -> String {
        return "Cancel"
    }
    
    func doneButtonPressed(button: UIBarButtonItem) {
        companyTextField.resignFirstResponder()
        if let rowSelected = companyTextField.pickerView?.selectedRow(inComponent: 0) {
            createContactViewModel.selectCompany(IndexPath(row: rowSelected, section: 0))
        }
    }
    
    func cancelButtonPressed(cancel: UIBarButtonItem) {
        companyTextField.resignFirstResponder()
    }
    
}
