//
//  PickerTextField.swift
//  Persistence_CoreData
//
//  Created by eli on 1/1/17.
//  Copyright © 2017 Eli Pacheco Hoyos. All rights reserved.
//

import UIKit

@objc protocol PicketTextFieldActionProtocol: class {
    func doneButtonPressed(button: UIBarButtonItem)
    func cancelButtonPressed(cancel: UIBarButtonItem)
    func doneTitle() -> String
    func cancelTitle() -> String
}

class PickerTextField: UITextField {

    var pickerView: UIPickerView?
    weak var pickerViewDataSource: UIPickerViewDataSource?
    weak var pickerViewDelegate: UIPickerViewDelegate?
    weak var pickerToolbarActionDelegate: PicketTextFieldActionProtocol?
    
    override func awakeFromNib() {
        if let delegate = pickerViewDelegate,
            let dataSource = pickerViewDataSource,
            let toolbarDelegate = pickerToolbarActionDelegate {
            pickerView = UIPickerView()
            pickerView?.delegate = delegate
            pickerView?.dataSource = dataSource
            self.inputView = pickerView
            self.inputAccessoryView = toolBarWith(toolbarDelegate)
        }
    }

    private func toolBarWith(_ delegate: PicketTextFieldActionProtocol) -> UIToolbar {
    
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        toolBar.sizeToFit()
        
        let doneSelector = #selector(PicketTextFieldActionProtocol.doneButtonPressed(button:))
        let doneButton = UIBarButtonItem(title: delegate.doneTitle(),
                                         style: UIBarButtonItemStyle.plain,
                                         target: delegate,
                                         action: doneSelector)
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace,
                                          target: nil,
                                          action: nil)
        let cancelSelector = #selector(PicketTextFieldActionProtocol.cancelButtonPressed(cancel:))
        let cancelButton = UIBarButtonItem(title: delegate.cancelTitle(),
                                           style: UIBarButtonItemStyle.plain,
                                           target: delegate,
                                           action: cancelSelector)
        
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        return toolBar
    }
    
    func reload() {
        pickerView?.reloadAllComponents()
    }
    
}
