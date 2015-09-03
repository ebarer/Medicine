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
            let hr = Int(medicine.interval)
            let min = Int(60 * (medicine.interval % 1))
            let hrUnit = medicine.intervalUnit.units(medicine.interval)
            
            if hr == 1 && min == 0 {
                intervalLabel.text = String(format:"Every %@", hrUnit.capitalizedString)
            } else if min == 0 {
                intervalLabel.text = String(format:"Every %d %@", hr, hrUnit)
            } else if hr == 0 {
                intervalLabel.text = String(format:"Every %d min", min)
            } else {
                intervalLabel.text = String(format:"Every %d %@ %d min", hr, hrUnit, min)
            }
            
            // Append alarm time for daily interval
            if medicine.intervalUnit == .Daily {
                if let alarm = medicine.intervalAlarm {
                    if medicine.isMidnight() {
                        intervalLabel.text?.appendContentsOf(" at Midnight")
                    } else {
                        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
                        dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
                        intervalLabel.text?.appendContentsOf(String(format:" at %@", dateFormatter.stringFromDate(alarm)))
                    }
                }
            }
        }
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == Rows.dosage.index().section {
            if editMode {
                return "Changes will take effect with next dose taken."
            }
        }
        
        if section == Rows.prescription.index().section {
            return "Keep track of your prescription levels, and be reminded to refill when running low."
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
    case none = -1
    case name
    case dosage
    case interval
    case scheduleSelect
    case prescription
    
    init(index: NSIndexPath) {
        var row = Rows.none
        
        switch (index.section, index.row) {
        case (0, 0):
            row = Rows.name
        case (1, 0):
            row = Rows.dosage
        case (1, 1):
            row = Rows.interval
        case (2, 0):
            row = Rows.scheduleSelect
        case (2, 1):
            row = Rows.prescription
        default:
            row = Rows.none
        }
        
        self = row
    }
    
    func index() -> NSIndexPath {
        switch self {
        case .name:
            return NSIndexPath(forRow: 0, inSection: 0)
        case .dosage:
            return NSIndexPath(forRow: 0, inSection: 1)
        case .interval:
            return NSIndexPath(forRow: 1, inSection: 1)
        case .scheduleSelect:
            return NSIndexPath(forRow: 0, inSection: 2)
        case .prescription:
            return NSIndexPath(forRow: 1, inSection: 2)
        default:
            return NSIndexPath(forRow: 0, inSection: 0)
        }
    }
}
