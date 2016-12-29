//
//  FormController.swift
//  Persistence_CoreData
//
//  Created by eli on 12/29/16.
//  Copyright © 2016 Eli Pacheco Hoyos. All rights reserved.
//

import Foundation
import UIKit

class FormController: UIViewController {

    @IBOutlet dynamic weak var formScrollView: UIScrollView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        unregisterKeyboardNotifications()
    }
    
    //MARK: Notification Methods
    
    func keyboardWillShow(notification: Notification) {
        guard let keyboardSize = keyboardSize(notification: notification) else { return }
        let contentInsets = UIEdgeInsetsMake(0, 0, keyboardSize.height, 0)
        formScrollView.contentInset = contentInsets
        formScrollView.scrollIndicatorInsets = contentInsets
        
        if let activeTextField = firstResponder() {
            let activeTextFieldFrame = activeTextField.frame
            var viewFrame = self.view.frame
            viewFrame.size.height -= keyboardSize.height
            
            if !viewFrame.contains(activeTextFieldFrame) {
                formScrollView.scrollRectToVisible(activeTextFieldFrame, animated: true)
            }
        }
        
    }
    
    func keyboardWillHide(notification: Notification) {
        let normalContentInsets = UIEdgeInsets.zero
        formScrollView.contentInset = normalContentInsets
        formScrollView.scrollIndicatorInsets = normalContentInsets
    }
    
    //MARK: Keyboard Functions
    
    func registerKeyboardNotifications() {
        let keyBoardWillShowSelector = #selector(FormController.keyboardWillShow(notification:))
        NotificationCenter.default.addObserver(self,
                                               selector: keyBoardWillShowSelector,
                                               name: Notification.Name.UIKeyboardWillShow,
                                               object: nil)
        let keyboardWillDissmisSelector = #selector(FormController.keyboardWillHide(notification:))
        NotificationCenter.default.addObserver(self,
                                               selector: keyboardWillDissmisSelector,
                                               name: Notification.Name.UIKeyboardWillHide,
                                               object: nil)
    }
    
    func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardSize(notification: Notification) -> CGSize? {
        if let keyboardInfo = notification.userInfo {
            if let kbSize = keyboardInfo[UIKeyboardFrameBeginUserInfoKey] as? CGRect {
                return kbSize.size
            }
        }
        
        return  nil
    }
    
    func inputViews() -> [UIView]? {
        return nil
    }
    
    func firstResponder() -> UIView? {

        guard let views = inputViews() else { return nil }
        
        for view in views {
            if view.isFirstResponder {
                return view
            }
        }
        
        return nil
    }
    
}
