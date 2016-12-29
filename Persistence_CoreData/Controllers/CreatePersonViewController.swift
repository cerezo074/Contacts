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
    @IBOutlet weak var companyTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    var createContactViewModel: CreatePersonViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapOnFormScrollSelector = #selector(CreatePersonViewController.formScrollViewWasTapped(gesture:))
        let tapGestureOnFormScroll = UITapGestureRecognizer(target: self, action: tapOnFormScrollSelector)
        formScrollView.addGestureRecognizer(tapGestureOnFormScroll)
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
    
    //MARK: IBAction Methods
    
    @IBAction func saveButtonIsPressed(_ sender: Any) {
        
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
