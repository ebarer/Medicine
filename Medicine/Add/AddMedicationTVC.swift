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
    
    @IBOutlet var intervalUnit: UITextField!
    @IBOutlet var interval: UITextField!
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if editMode == true {
            medicationName.text = med?.name
            
            if let medInterval = med?.interval {
                interval.text = String(medInterval)
            }
            
            if let medIntervalUnit = med?.intervalUnit {
                intervalUnit.text = String(medIntervalUnit)
            }
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
    
    @IBAction func updateName(sender: UITextField) {
        med?.name = sender.text
    }
    
    @IBAction func updateInterval(sender: UITextField) {
        if let text = sender.text {
            med?.interval = (text as NSString).floatValue
        }
    }
}
