//
//  AddDoseTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-31.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class AddDoseTVC: UITableViewController {
    
    var med:Medicine?
    
    var globalHistory: Bool = false
    var date = NSDate()
    let cal = NSCalendar.currentCalendar()
    
    
    // MARK: - Outlets
    
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var medCell: UITableViewCell!
    @IBOutlet var medLabel: UILabel!
    @IBOutlet var doseLabel: UILabel!
    @IBOutlet var picker: UIDatePicker!
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        
        // Set picker min/max values
        picker.maximumDate = NSDate()

        // Remove tableView gap
        tableView.tableHeaderView = UIView(frame: CGRectMake(0.0, 0.0, tableView.bounds.size.width, 0.01))
    }
    
    override func viewWillAppear(animated: Bool) {
        if let index = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(index, animated: animated)
        }
        
        // Prevent modification of medication when not in global history
        if !globalHistory {
            medCell.accessoryType = UITableViewCellAccessoryType.None
            medCell.selectionStyle = UITableViewCellSelectionStyle.None
        }
        
        updateLabels()
        
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateLabels() {
        // Set medicine label
        if let med = med {
            medLabel.text = med.name
            doseLabel.text = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
            
            // Check prescription levels
            if (med.dosage > med.prescriptionCount) {
                saveButton.enabled = false
            } else {
                saveButton.enabled = true
            }
        } else {
            if let med = medication.first {
                self.med = med
                medLabel.text = med.name
                doseLabel.text = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
                saveButton.enabled = true
            } else {
                medLabel.text = "None"
                doseLabel.text = "None"
                saveButton.enabled = false
            }
        }
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath == NSIndexPath(forRow: 0, inSection: 0) {
            return 216.0
        }
        
        return tableView.rowHeight
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            if let med = med {
                let count = med.prescriptionCount
                
                if (count < med.dosage) {
                    return "You do not appear to have enough medication remaining to take this dose. " +
                           "Tap \"Refill Prescription\" to update your prescription amount."
                } else {
                    return "You currently have " +
                           "\(count) \(med.dosageUnit.units(count)) of \(med.name!). " +
                           "Based on your current usage, this will last you approximately \(med.refillDaysRemaining()) days."
                }
            }
        }
        
        return nil
    }
    
    
    // MARK: - Actions
    
    @IBAction func updateDate(sender: UIDatePicker) {
        date = sender.date
    }
    
    
    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if !globalHistory && identifier == "selectMedicine" {
            return false
        }
        
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? AddDoseTVC_Medicine {
            vc.selectedMed = med
        }
        
        if let vc = segue.destinationViewController as? AddMedicationTVC_Dosage {
            vc.med = med
            vc.editMode = true
        }
        
        if segue.identifier == "refillPrescription" {
            if let vc = segue.destinationViewController.childViewControllers[0] as? AddRefillTVC {
                vc.med = med
            }
        }
    }
    
    @IBAction func medicationUnwindSelect(unwindSegue: UIStoryboardSegue) {
        if let svc = unwindSegue.sourceViewController as? AddDoseTVC_Medicine, selectedMed = svc.selectedMed {
            med = selectedMed
            medLabel.text = selectedMed.name
            doseLabel.text = String(format:"%g %@", med!.dosage, med!.dosageUnit.units(med!.dosage))
            self.navigationItem.rightBarButtonItem?.enabled = true
        }
        
        if let svc = unwindSegue.sourceViewController as? AddMedicationTVC_Dosage, med = svc.med {
            doseLabel.text = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
        }
    }
    
    @IBAction func dismissView(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }

}