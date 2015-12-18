//
//  AddMedicationTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-27.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class AddMedicationTVC: UITableViewController, UITextFieldDelegate, UITextViewDelegate {
    
    var med: Medicine!
    var editMode: Bool = false
    
    
    // MARK: - Outlets
    
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var medicationName: UITextField!
    @IBOutlet var dosageLabel: UILabel!
    @IBOutlet var reminderToggle: UISwitch!
    @IBOutlet var intervalLabel: UILabel!
    @IBOutlet var prescriptionLabel: UILabel!
    
    
    // MARK: - Helper variables
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext
    let cal = NSCalendar.currentCalendar()
    let dateFormatter = NSDateFormatter()
    
    
    // MARK: - Initialization
    
    required init?(coder aDecoder: NSCoder) {
        // Setup context
        moc = appDelegate.managedObjectContext
        
        // Setup date formatter
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
        
        super.init(coder: aDecoder)
    }

    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        self.medicationName.delegate = self
        
        // Modify VC
        self.view.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        
        // Setup medicine object
        if editMode == false {
            let entity = NSEntityDescription.entityForName("Medicine", inManagedObjectContext: moc)
            med = Medicine(entity: entity!, insertIntoManagedObjectContext: moc)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect selected row
        if let index = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(index, animated: animated)
        }
        
        if !editMode {
            self.title = "New Medication"
        } else {
            self.title = "Edit Medication"
            prescriptionLabel.text = "Refill Prescription"
        }
        
        updateLabels()

        tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if med.name == nil || med.name?.isEmpty == true {
            medicationName.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateLabels() {
        // Set name label
        medicationName.text = med.name
        
        // Set dosage label
        dosageLabel.text = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
        
        // Set reminder toggle
        reminderToggle.on = med.reminderEnabled
        
        // Set interval label
        intervalLabel.text = "Every " + med.intervalLabel()
        
        // If medication has no name, disable save button
        if med.name == nil || med.name?.isEmpty == true {
            saveButton.enabled = false
            self.navigationItem.backBarButtonItem?.title = "Back"
        } else {
            saveButton.enabled = true
            self.navigationItem.backBarButtonItem?.title = med.name
        }
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case Rows.prescription.index().section:
            if med.name != nil && med.name != "" {
                return tableView.rowHeight
            }
        default:
            return UITableViewAutomaticDimension
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = Rows(index: indexPath)
        
        switch row {
        case Rows.name:
            return 60.0
        case Rows.prescription:
            if med.name != nil && med.name != "" {
                return 48.0
            }
        case Rows.interval:
            if med.reminderEnabled == true {
                return tableView.rowHeight
            }
        default:
            return tableView.rowHeight
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let row = Rows(index: indexPath)
        
        cell.preservesSuperviewLayoutMargins = true
        
        switch(row) {
        case Rows.dosage:
            if med.reminderEnabled == false {
                cell.preservesSuperviewLayoutMargins = false
                cell.layoutMargins = UIEdgeInsetsZero
                cell.separatorInset = UIEdgeInsetsZero
                cell.contentView.layoutMargins = tableView.separatorInset
            }
        default: break
        }
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case Rows.prescription.index().section:
            if med.name != nil && med.name != "" {
                return tableView.rowHeight
            }
        default:
            return UITableViewAutomaticDimension
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == Rows.prescription.index().section {
            if med.refillHistory?.count > 0 {
                return med.refillStatus()
            } else if med.name != nil && med.name != "" {
                return "Keep track of your prescription levels, and be reminded to refill when running low."
            }
        }
        
        return nil
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let row = Rows(index: indexPath)
        
        switch row {
        case Rows.prescription:
            if med.name == nil || med.name == "" {
                return false
            }
        default:
            return true
        }
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    // MARK: - Actions
    
    @IBAction func updateName(sender: UITextField) {
        let temp = med.name
        med.name = sender.text
        updateLabels()
        
        // Reload table view
        if temp == nil || temp == "" || sender.text!.isEmpty {
            tableView.reloadSections(NSIndexSet(index: Rows.prescription.index().section), withRowAnimation: .Automatic)
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    @IBAction func toggleReminder(sender: UISwitch) {
        med.reminderEnabled = sender.on

        // Update rows
        tableView.reloadRowsAtIndexPaths([Rows.dosage.index()], withRowAnimation: UITableViewRowAnimation.None)
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if med.name == nil || med.name == "" {
            if identifier == "refillPrescription" {
                return false
            }
        }
        
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "setDosage" {
            if let vc = segue.destinationViewController as? AddMedicationTVC_Dosage {
                vc.med = self.med
                vc.editMode = self.editMode
            }
        }
        
        if segue.identifier == "setInterval" {
            if let vc = segue.destinationViewController as? AddMedicationTVC_Interval {
                vc.med = self.med
                vc.editMode = self.editMode
            }
        }
        
        if segue.identifier == "refillPrescription" {
            if let vc = segue.destinationViewController.childViewControllers[0] as? AddRefillTVC {
                vc.med = self.med
            }
        }
    }
    
    @IBAction func saveMedication(sender: AnyObject) {
        if !editMode {
            let insertIndex = NSIndexPath(forRow: medication.count, inSection: 0)
            med.sortOrder = Int16(insertIndex.row)
            medication.append(med)
        } else {
            if let lastDose = med.lastDose {
                do {
                    lastDose.next = try med.calculateNextDose(lastDose.date)
                } catch {
                    print("Unable to update last dose")
                }
            }
        }
        
        appDelegate.saveContext()
        
        // Reschedule next notification
        med.scheduleNextNotification()
        
        NSNotificationCenter.defaultCenter().postNotificationName("refreshMedication", object: nil, userInfo: nil)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancelMedication(sender: AnyObject) {
        if !editMode {
            moc.deleteObject(med)
        } else {
            moc.rollback()
        }
        
        appDelegate.saveContext()
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}


private enum Rows: Int {
    case none = -1
    case name
    case reminderEnable
    case dosage
    case interval
    case prescription
    
    init(index: NSIndexPath) {
        var row = Rows.none
        
        switch (index.section, index.row) {
        case (0, 0):
            row = Rows.name
        case (0, 1):
            row = Rows.reminderEnable
        case (1, 0):
            row = Rows.dosage
        case (1, 1):
            row = Rows.interval
        case (2, 0):
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
        case .reminderEnable:
            return NSIndexPath(forRow: 1, inSection: 0)
        case .dosage:
            return NSIndexPath(forRow: 0, inSection: 1)
        case .interval:
            return NSIndexPath(forRow: 1, inSection: 1)
        case .prescription:
            return NSIndexPath(forRow: 0, inSection: 2)
        default:
            return NSIndexPath(forRow: 0, inSection: 0)
        }
    }
}
