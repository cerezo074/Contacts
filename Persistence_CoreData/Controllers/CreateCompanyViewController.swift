//
//  CreateCompanyViewController.swift
//  Persistence_CoreData
//
//  Created by Eli Pacheco Hoyos on 12/22/16.
//  Copyright © 2016 Eli Pacheco Hoyos. All rights reserved.
//

import UIKit

class CreateCompanyViewController: FormController {
    
    @IBOutlet weak var companyNameTextField: UITextField!
    @IBOutlet weak var companyAddressTextField: UITextField!
    @IBOutlet weak var companyEmailTextField: UITextField!
    @IBOutlet weak var companyTelephoneTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    var createCompanyViewModel: CreateCompanyViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        bindCreateActionState()
        companyNameTextField.text = "Atletico Nacional"
        companyAddressTextField.text = "Cra 80 # 34 - 12"
        companyEmailTextField.text = "Verdolaga@verde.com"
        companyTelephoneTextField.text = "1234567890"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func bindCreateActionState() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        createCompanyViewModel.createCompanyListener = {
            [weak self, weak appDelegate] state in
            switch state {
            case .companyCreated(let error):
                guard let message = error else {
                    appDelegate?.contactsFlowCoordinator.companyWasCreated(self)
                    return
                }
                self?.showResultActionMessage("Create Company", message)
                break
            default:
                break
            }
        }
    }
    
    override func inputViews() -> [UIView]? {
        return [
            companyNameTextField,
            companyAddressTextField,
            companyEmailTextField,
            companyTelephoneTextField
        ]
    }
    
    //MARK: IBAction Methods
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        
        guard let name = companyNameTextField.text,
            let address = companyAddressTextField.text,
            let email = companyEmailTextField.text,
            let telephone = companyEmailTextField.text else {
                showResultActionMessage("Create Company", "Please you must fill all fields.")
                return
        }
        
        createCompanyViewModel.createNewCompany(name: name,
                                                address: address,
                                                email: email,
                                                telephone: telephone)
    }

}

extension CreateCompanyViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
