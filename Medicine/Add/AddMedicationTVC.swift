//
//  AddMedicationTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-27.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class AddMedicationTVC: UITableViewController, UITextFieldDelegate, UITextViewDelegate {
    
    var med: Medicine?
    var editMode: Bool = false
    
    // MARK: - Outlets
    
    @IBOutlet var medicationName: UITextField!
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(med)
        
        if editMode == true {
            
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if medicationName.text!.isEmpty {
            medicationName.becomeFirstResponder()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    // MARK: - Set medicine values
    
    @IBAction func setName(sender: UITextField) {
        med?.name = sender.text
    }
    
    @IBAction func setInterval(sender: UITextField) {
        if let text = sender.text {
            med?.interval = (text as NSString).floatValue
        }
    }
}
