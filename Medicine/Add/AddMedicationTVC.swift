//
//  AddMedicationTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-27.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class AddMedicationTVC: UITableViewController, UITextFieldDelegate, UITextViewDelegate, UIPickerViewDelegate {
    
    weak var med: Medicine?
    
    
    // MARK: - Helper variables
    
    let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    let dateFormatter = NSDateFormatter()
    
    
    // MARK: - Outlets
    
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var medicationName: UITextField!
    @IBOutlet var dosageLabel: UILabel!
    @IBOutlet var intervalLabel: UILabel!
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let medicine = med {
            medicationName.text = medicine.name
            
            // Disable save button
            if medicine.name?.isEmpty == true {
                saveButton.enabled = false
            }

            // Set dosage label
            dosageLabel.text = String(format:"%g %@", medicine.dosage, medicine.dosageUnit.units(medicine.dosage))
            
            // Set interval label
            intervalLabel.text = String(format:"Every %g %@", medicine.interval, medicine.intervalUnit.units(medicine.interval))
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if medicationName.text!.isEmpty {
            medicationName.becomeFirstResponder()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("AddMedicationTVC")
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
    
    
    // MARK: - Picker delegate/data source
    
//    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
//        if (pickerView == dosagePicker) {
//            return 3
//        }
//        
//        return 1
//    }
//    
//    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        if (pickerView == dosagePicker) {
//            switch(component) {
//            case 0:
//                return 20
//            case 1:
//                return 10
//            case 2:
//                return 3
//            default:
//                return 1
//            }
//        }
//        
//        return 1
//    }
//    
//    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        if (pickerView == dosagePicker) {
//            switch(component) {
//            case 0:
//                return String(row)
//            case 1:
//                return String(row)
//            case 2:
//                return Doses(rawValue: Int16(row))?.description
//            default:
//                return nil
//            }
//        }
//        
//        return nil
//    }
    
    
    // MARK: - Set medicine values
    
    @IBAction func updateName(sender: UITextField) {
        med?.name = sender.text
        
        if med?.name?.isEmpty == true {
            saveButton.enabled = false
        } else {
            saveButton.enabled = true
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





