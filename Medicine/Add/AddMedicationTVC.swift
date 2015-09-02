//
//  AddMedicationTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-27.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class AddMedicationTVC: UITableViewController, UITextFieldDelegate, UITextViewDelegate {
    
    weak var med: Medicine?
    var editMode: Bool = false
    
    
    // MARK: - Outlets
    
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var medicationName: UITextField!
    @IBOutlet var dosageLabel: UILabel!
    @IBOutlet var intervalLabel: UILabel!
    
    
    // MARK: - Helper variables
    
    let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    let dateFormatter = NSDateFormatter()
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.tintColor = UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0)
    }
    
    override func viewDidAppear(animated: Bool) {
        if let medicine = med {
            if medicine.name == nil || medicine.name?.isEmpty == true {
                medicationName.becomeFirstResponder()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        if let index = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(index, animated: animated)
        }
        
        updateLabels()
    }
    
    override func viewWillDisappear(animated: Bool) {
        medicationName.resignFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("AddMedicationTVC")
    }
    
    func updateLabels() {
        if let medicine = med {
            medicationName.text = medicine.name
            
            // If medication has no name, disable save button
            if medicine.name == nil || medicine.name?.isEmpty == true {
                saveButton.enabled = false
                self.navigationItem.backBarButtonItem?.title = "Back"
            } else {
                saveButton.enabled = true
                self.navigationItem.backBarButtonItem?.title = med?.name
            }
            
            // Set dosage label
            dosageLabel.text = String(format:"%g %@", medicine.dosage, medicine.dosageUnit.units(medicine.dosage))
            
            // Set interval label
            intervalLabel.text = String(format:"Every %g %@", medicine.interval, medicine.intervalUnit.units(medicine.interval))
        }
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == Rows.dosage.rawValue {
            if editMode {
                return "Changes will take effect with next dose taken."
            }
        }
        
        if section == Rows.prescription.rawValue {
            return "Keep track of your prescription details and be alerted when you need to refill"
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
        updateLabels()
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? AddMedicationTVC_Dosage {
            vc.med = self.med
        }
        
        if let vc = segue.destinationViewController as? AddMedicationTVC_Interval {
            vc.med = self.med
        }
    }
    
}

private enum Rows: Int {
    case name = 0
    case dosage = 1
    case prescription = 2
}





