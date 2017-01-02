//
//  PickerTextField.swift
//  Persistence_CoreData
//
//  Created by eli on 1/1/17.
//  Copyright © 2017 Eli Pacheco Hoyos. All rights reserved.
//

import UIKit

@objc protocol PickerTextToolbarDelegate: class {
    func doneButtonPressed(button: UIBarButtonItem)
    func cancelButtonPressed(cancel: UIBarButtonItem)
    func doneTitle() -> String
    func cancelTitle() -> String
    func tintColor() -> UIColor
}

class PickerTextField: UITextField {

    var pickerView: UIPickerView?
    weak var pickerViewDataSource: UIPickerViewDataSource?
    weak var pickerViewDelegate: UIPickerViewDelegate?
    weak var toolbarDelegate: PickerTextToolbarDelegate?
    
    func setDelegates(delegate pickerViewDelegate: UIPickerViewDelegate,
                        datasource pickerViewDataSource: UIPickerViewDataSource,
                        toolbarDelegate: PickerTextToolbarDelegate) {
        pickerView = UIPickerView()
        pickerView?.delegate = pickerViewDelegate
        pickerView?.dataSource = pickerViewDataSource
        self.inputView = pickerView
        self.inputAccessoryView = toolBarWith(toolbarDelegate)
    }

    private func toolBarWith(_ delegate: PickerTextToolbarDelegate) -> UIToolbar {
    
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = delegate.tintColor()
        toolBar.sizeToFit()
        
        let doneSelector = #selector(PickerTextToolbarDelegate.doneButtonPressed(button:))
        let doneButton = UIBarButtonItem(title: delegate.doneTitle(),
                                         style: UIBarButtonItemStyle.plain,
                                         target: delegate,
                                         action: doneSelector)
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace,
                                          target: nil,
                                          action: nil)
        let cancelSelector = #selector(PickerTextToolbarDelegate.cancelButtonPressed(cancel:))
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
