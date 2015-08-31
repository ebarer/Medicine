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
    @IBOutlet var dosageUnit: UITextField!
    @IBOutlet var dosage: UITextField!
    @IBOutlet var intervalUnit: UITextField!
    @IBOutlet var interval: UITextField!
    @IBOutlet var timeStart: UITextField!
    @IBOutlet var timeEnd: UITextField!

    
    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if editMode == true {
            medicationName.text = med?.name

            dosageUnit.text = med?.dosageUnit.units(med?.dosage)
            dosage.text = med?.dosage.description
            
            intervalUnit.text = med?.intervalUnit.units(med?.interval)
            interval.text = med?.interval.description
            
            //timeEnd: NSTimeInterval
            //timeStart: NSTimeInterval
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
    
    
    // MARK: - Table view delegate
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 2 {
            return "Take this medication every \(med!.interval) \(med!.intervalUnit.units(med!.interval)) until midnight."
        }
        
        return nil
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    // MARK: - Set medicine values
    @IBAction func updateName(sender: UITextField) {
        med?.name = sender.text
    }
    
    @IBAction func updateDosageUnit(sender: UITextField) {
        if let text = sender.text {
            if let raw = Int16(text) {
                if raw < Doses.count {
                    med?.dosageUnit = Doses(rawValue: raw)!
                }
            }
        }
    }
    
    @IBAction func updateDose(sender: UITextField) {
        if let text = sender.text {
            med?.dosage = (text as NSString).floatValue
        }
    }
    
    @IBAction func updateIntervalUnit(sender: UITextField) {
        if let text = sender.text {
            if let raw = Int16(text) {
                if raw < Intervals.count {
                    med?.intervalUnit = Intervals(rawValue: raw)!
                }
            }
        }
    }
    
    @IBAction func updateInterval(sender: UITextField) {
        if let text = sender.text {
            med?.interval = (text as NSString).floatValue
        }
    }
}





