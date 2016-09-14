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
    
    var med: Medicine?
    var dose: Dose

    
    // MARK: - Outlets
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var picker: UIDatePicker!
    @IBOutlet var medCell: UITableViewCell!
    @IBOutlet var medLabel: UILabel!
    @IBOutlet var doseCell: UITableViewCell!
    @IBOutlet var doseLabel: UILabel!
    @IBOutlet var prescriptionCell: UITableViewCell!
    
    
    // MARK: - Helper variables
    let defaults = NSUserDefaults(suiteName: "group.com.ebarer.Medicine")!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext
    
    let cal = NSCalendar.currentCalendar()
    let dateFormatter = NSDateFormatter()
    var globalHistory: Bool = false
    
    
    // MARK: - Initialization
    required init?(coder aDecoder: NSCoder) {
        // Setup context
        moc = appDelegate.managedObjectContext
        
        // Setup date formatter
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
        
        let entity = NSEntityDescription.entityForName("Dose", inManagedObjectContext: moc)
        dose = Dose(entity: entity!, insertIntoManagedObjectContext: moc)
        dose.date = NSDate()
        
        super.init(coder: aDecoder)
    }
    
    
    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true

        // Modify VC
        self.view.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        tableView.tableHeaderView = UIView(frame: CGRectMake(0.0, 0.0, tableView.bounds.size.width, 0.01))  // Remove tableView gap

        // Prevent modification of medication when not in global history
        if !globalHistory {
            medCell.accessoryType = UITableViewCellAccessoryType.None
            medCell.selectionStyle = UITableViewCellSelectionStyle.None
        }

        // Set picker min/max values
        picker.maximumDate = NSDate()
        
        updateDoseValues()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect selected row
        if let index = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(index, animated: animated)
        }

        updateDoseValues()
        updateLabels()
        
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateDoseValues() {
        if let med = self.med {
            dose.medicine = med
            dose.dosage = med.dosage
            dose.dosageUnitInt = med.dosageUnitInt
        } else if let med = medication.first {
            self.med = med
            dose.medicine = med
            dose.dosage = med.dosage
            dose.dosageUnitInt = med.dosageUnitInt
        }
    }
    
    func updateLabels() {
        // If no medication selected, force user to select a medication
        if med == nil {
            medLabel.text = "None"
            doseLabel.text = "None"
            
            doseCell.selectionStyle = .None
            prescriptionCell.selectionStyle = .None
            saveButton.enabled = false
        } else {
            picker.setDate(dose.date, animated: true)
            
            medLabel.text = med?.name
            doseLabel.text = String(format:"%g %@", dose.dosage, dose.dosageUnit.units(dose.dosage))
            
            doseCell.selectionStyle = .Default
            prescriptionCell.selectionStyle = .Default
            saveButton.enabled = true
        }
        
        // If insufficient prescription levels,
        // if dose.dosage > dose.medicine?.prescriptionCount {
    }
    
    
    // MARK: - Table view data source
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath == NSIndexPath(forRow: 0, inSection: 0) {
            return 216.0
        } else if indexPath == NSIndexPath(forRow: 2, inSection: 0) {
            return 48.0
        }
        
        return tableView.rowHeight
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if let med = med where section == 0 {
            return med.refillStatus()
        }
        
        return nil
    }
    
    
    // MARK: - Actions
    @IBAction func updateDate(sender: UIDatePicker) {
        dose.date = sender.date
    }
    
    
    // MARK: - Navigation
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        // Prevent segues if no medication selected (except to select a medication)
        if med == nil && identifier != "selectMedicine" {
            return false
        }
        
        // Prevent changing medicine unless adding dose from global history view
        if !globalHistory && identifier == "selectMedicine" {
            return false
        }
        
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "selectMedicine" {
            if let vc = segue.destinationViewController as? AddDoseTVC_Medicine {
                vc.selectedMed = med
            }
        }

        if segue.identifier == "setDosage" {
            if let vc = segue.destinationViewController as? AddMedicationTVC_Dosage {
                vc.med = med
                vc.editMode = true
            }
        }
        
        if segue.identifier == "refillPrescription" {
            if let vc = segue.destinationViewController.childViewControllers[0] as? AddRefillTVC {
                vc.med = med
                if let index = tableView.indexPathForSelectedRow {
                    self.tableView.deselectRowAtIndexPath(index, animated: false)
                }
            }
        }
    }
    
    @IBAction func medicationUnwindSelect(unwindSegue: UIStoryboardSegue) {
        if let vc = unwindSegue.sourceViewController as? AddDoseTVC_Medicine {
            self.med = vc.selectedMed
        }
    }
    
    @IBAction func saveDose(sender: AnyObject) {
        if let med = self.med {
            do {
                // Save dose
                try med.takeDose(dose)
                
                // Check if medication needs to be refilled
                let refillTime = defaults.integerForKey("refillTime")
                if med.needsRefill(limit: refillTime) {
                    med.sendRefillNotification()
                }
                
                appDelegate.saveContext()
                
                NSNotificationCenter.defaultCenter().postNotificationName("refreshView", object: nil)
                NSNotificationCenter.defaultCenter().postNotificationName("refreshMain", object: nil)
                
                dismissViewControllerAnimated(true, completion: nil)
            } catch {
                presentDoseAlert()
            }
        } else {
            presentMedAlert()
        }
    }
    
    @IBAction func cancelDose(sender: AnyObject) {
        moc.deleteObject(dose)
        appDelegate.saveContext()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: - Error handling
    func presentMedAlert() {
            globalHistory = true
        
            let alert = UIAlertController(title: "Invalid Medication", message: "You have to select a valid medication.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.view.tintColor = UIColor.grayColor()
            self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func presentDoseAlert() {
        if let med = self.med {
            let doseAlert = UIAlertController(title: "Repeat Dose?", message: "You have logged a dose for \(med.name!) within the passed 5 minutes, do you wish to log another dose?", preferredStyle: UIAlertControllerStyle.Alert)
            
            doseAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            
            doseAlert.addAction(UIAlertAction(title: "Add Dose", style: UIAlertActionStyle.Destructive, handler: {(action) -> Void in
                self.appDelegate.saveContext()
                
                NSNotificationCenter.defaultCenter().postNotificationName("refreshView", object: nil)
                NSNotificationCenter.defaultCenter().postNotificationName("refreshMain", object: nil)
                
                self.dismissViewControllerAnimated(true, completion: nil)
            }))
            
            doseAlert.view.tintColor = UIColor.grayColor()
            self.presentViewController(doseAlert, animated: true, completion: nil)
        }
    }

}
