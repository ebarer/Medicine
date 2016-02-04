//
//  MedicineDetailsTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-12-05.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class MedicineDetailsTVC: UITableViewController {
    
    weak var med:Medicine?
    
    
    // MARK: - Outlets
    
    @IBOutlet var nameCell: UITableViewCell!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var doseDetailsLabel: UILabel!
    @IBOutlet var doseCell: UITableViewCell!
    @IBOutlet var doseTitle: UILabel!
    @IBOutlet var doseLabel: UILabel!
    @IBOutlet var prescriptionLabel: UILabel!
    @IBOutlet var actionCell: UITableViewCell!
    @IBOutlet var takeDoseButton: UIButton!
    @IBOutlet var refillButton: UIButton!

    
    // MARK: - Helper variables
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext!
    
    let cal = NSCalendar.currentCalendar()
    let dateFormatter = NSDateFormatter()
    
    
    // MARK: - Initialization
    
    required init?(coder aDecoder: NSCoder) {
        // Setup context
        moc = appDelegate.managedObjectContext
        super.init(coder: aDecoder)
    }
    
    
    // MARK: - View methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup edit button
        let editButton = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: "editMedication")
        self.navigationItem.rightBarButtonItem = editButton
        
        // Add observeres for notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshDetails", name: "refreshView", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect selected row
        if let index = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(index, animated: animated)
        }
        
        if let tBC = self.tabBarController {
            tBC.setTabBarVisible(true, animated: false)
            self.navigationController?.setToolbarHidden(true, animated: false)
        }
        
        // Update actions
        actionCell.backgroundColor = tableView.separatorColor
        takeDoseButton.backgroundColor = UIColor.whiteColor()
        refillButton.backgroundColor = UIColor.whiteColor()
        
        displayEmptyView()
        updateLabels()
        
        tableView.reloadSections(NSIndexSet(index: Rows.name.index().section), withRowAnimation: .None)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func refreshDetails() {
        displayEmptyView()
        updateLabels()
    }
    
    func displayEmptyView() {
        if med == nil {
            if self.view.viewWithTag(1001) == nil {     // Prevent duplicate empty views being added
                if let emptyView = UINib(nibName: "DetailEmptyView", bundle: nil).instantiateWithOwner(self, options: nil)[0] as? UIView {
                    emptyView.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
                    emptyView.tag = 1001
                    self.view.addSubview(emptyView)
                    self.tableView.scrollEnabled = false
                    self.navigationItem.rightBarButtonItem?.enabled = false
                }
            }
        } else {
            self.view.viewWithTag(1001)?.removeFromSuperview()
            self.tableView.scrollEnabled = true
            self.navigationItem.rightBarButtonItem?.enabled = true
        }
    }
    
    func updateLabels() {
        if let med = med {
            nameLabel.textColor = UIColor.blackColor()
            nameLabel.text = med.name
            
            var detailsString = "\(med.removeTrailingZero(med.dosage)) \(med.dosageUnit.units(med.dosage))"
            if med.reminderEnabled == true {
                detailsString += ", every \(med.removeTrailingZero(med.interval)) \(med.intervalUnit.units(med.interval))"
            }
            
            doseDetailsLabel.text = detailsString
            
            var prescriptionString = ""
            if med.refillHistory?.count > 0 {
                let count = med.prescriptionCount
                let numberFormatter = NSNumberFormatter()
                numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
                
                if count.isZero {
                    prescriptionString = "None remaining"
                } else if let count = numberFormatter.stringFromNumber(count) {
                    prescriptionString = "\(count) \(med.dosageUnit.units(med.prescriptionCount)) remaining"
                }
            } else {
                prescriptionString = "None"
            }
            
            prescriptionLabel.text = prescriptionString
            
            updateDose()
            
            // Correct inset
            tableView.reloadRowsAtIndexPaths([Rows.name.index()], withRowAnimation: .None)
        }
    }
    
    func updateDose() {
        if let med = med {
            // Set defaults
            nameCell.imageView?.image = nil
            nameLabel.textColor = UIColor.blackColor()
            
            doseTitle.textColor = UIColor.lightGrayColor()
            doseTitle.text = "Next Dose"
            
            doseLabel.textColor = UIColor.blackColor()
            doseLabel.font = UIFont.systemFontOfSize(14.0, weight: UIFontWeightRegular)
            
            // If no doses taken
            if med.doseHistory?.count == 0 && med.intervalUnit == .Hourly {
                doseTitle.text = "No doses logged"
                doseLabel.text?.removeAll()
            }
            
            // If reminders aren't enabled for medication
            else if med.reminderEnabled == false {
                if let date = med.lastDose?.date {
                    doseTitle.text = "Last Dose"
                    doseLabel.text = Medicine.dateString(date)
                } else {
                    doseTitle.text = "No doses logged"
                    doseLabel.text?.removeAll()
                }
            } else {
                // If medication is overdue, set subtitle to next dosage date and tint red
                if med.isOverdue().flag {
                    nameCell.imageView?.image = UIImage(named: "OverdueIcon")
                    nameLabel.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
                    
                    doseTitle.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
                    doseTitle.text = "Overdue"

                    if let date = med.isOverdue().overdueDose {
                        doseLabel.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
                        doseLabel.font = UIFont.systemFontOfSize(14.0, weight: UIFontWeightSemibold)
                        doseLabel.text = Medicine.dateString(date)
                    }
                }
                    
                // If notification scheduled, set date to next scheduled fire date
                else if let date = med.scheduledNotifications?.first?.fireDate {
                    doseLabel.text = Medicine.dateString(date)
                }
                    
                // Set subtitle to next dosage date
                else if let date = med.nextDose {
                    doseLabel.text = Medicine.dateString(date)
                }
                    
                // If no other conditions met, instruct user on how to take dose
                else {
                    doseTitle.text = "No doses logged"
                    doseLabel.text?.removeAll()
                }
            }
        }
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return tableView.rowHeight
        case 1:
            if med?.prescriptionCount > 0 {
                return 20.0
            } else {
                return 5.0
            }
        default:
            return 5.0
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = Rows(index: indexPath)
        
        switch row {
        case Rows.name:
            return 60.0
        case Rows.prescriptionCount:
            if med?.refillHistory?.count > 0 {
                return tableView.rowHeight
            }
        case Rows.actions:
            return 50.0
        case Rows.doseHistory: fallthrough
        case Rows.refillHistory: fallthrough
        case Rows.delete:
            return 50.0
        default:
            return tableView.rowHeight
        }
        
        return 0.0
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let row = Rows(index: indexPath)
        
        cell.preservesSuperviewLayoutMargins = true
        
        switch(row) {
        case Rows.doseDetails:
            if med?.refillHistory?.count == 0 {
                cell.preservesSuperviewLayoutMargins = false
                cell.layoutMargins = UIEdgeInsetsZero
                cell.separatorInset = UIEdgeInsetsZero
                cell.contentView.layoutMargins = tableView.separatorInset
            }
        default: break
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if let med = med {
            if section == Rows.prescriptionCount.index().section && med.prescriptionCount > 0 {
                var status: String? = nil
                
                if med.prescriptionCount < med.dosage {
                    status = "You do not appear to have enough \(med.name!) remaining to take the next dose. "
                } else {                
                    if let days = med.refillDaysRemaining() {
                        if days <= 1 {
                            status = "You will need to refill after the next dose. "
                        } else {
                            status = "Based on current usage, your prescription should last approximately \(days) \(Intervals.Daily.units(Float(days))). "
                        }
                    } else {
                        status = "Continue taking doses to receive a duration approximation for your prescription."
                    }
                }
                
                return status
            }
        }
        
        return nil
    }
    
    
    // MARK: - Table view delegates
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = Rows(index: indexPath)
        
        switch row {
        case Rows.name:
            performSegueWithIdentifier("editMedication", sender: nil)
        case Rows.nextDose:
            performSegueWithIdentifier("addDose", sender: nil)
        case Rows.prescriptionCount:
            performSegueWithIdentifier("refillPrescription", sender: nil)
        case Rows.delete:
            presentDeleteAlert(indexPath)
        default: break
        }
    }


    // MARK: - Actions
    
    func editMedication() {
        performSegueWithIdentifier("editMedication", sender: nil)
    }
    
    @IBAction func actionSelected(sender: UIButton) {
        if med != nil {
            sender.backgroundColor = tableView.separatorColor
        }
    }
    
    @IBAction func actionDeselected(sender: UIButton) {
        sender.backgroundColor = UIColor.whiteColor()
    }

    func presentDeleteAlert(indexPath: NSIndexPath) {
        if let med = med {
            if let name = med.name {
                let deleteAlert = UIAlertController(title: "Delete \(name)?", message: "This will permanently delete \(name) and all of its history.", preferredStyle: UIAlertControllerStyle.Alert)
                
                deleteAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {(action) -> Void in
                    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                }))
                
                deleteAlert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: {(action) -> Void in
                    self.deleteMed()
                }))
                
                deleteAlert.view.tintColor = UIColor.grayColor()
                self.presentViewController(deleteAlert, animated: true, completion: nil)
            }
        } else {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    func deleteMed() {
        if let med = med {
            // Cancel all notifications for medication
            med.cancelNotifications()
            
            // Remove medication from array
            medication.removeObject(med)
            self.med = nil
            
            // Remove medication from persistent store
            moc.deleteObject(med)
            appDelegate.saveContext()

            // Send notifications
            NSNotificationCenter.defaultCenter().postNotificationName("refreshView", object: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("medicationDeleted", object: nil)
        }
    }
    
    
    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if med != nil {
            return true
        }
        
        // Deselect selected row
        if let index = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(index, animated: true)
        }
        
        return false
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let med = med {
            self.navigationItem.backBarButtonItem?.title = med.name
            
            if let button = sender as? UIButton {
                actionDeselected(button)
            }
            
            if segue.identifier == "editMedication" {
                if let vc = segue.destinationViewController.childViewControllers[0] as? AddMedicationTVC {
                    vc.med = self.med
                    vc.editMode = true
                }
            }
            
            if segue.identifier == "addDose" {
                if let vc = segue.destinationViewController.childViewControllers[0] as? AddDoseTVC {
                    vc.med = self.med
                }
            }
            
            if segue.identifier == "refillPrescription" {
                if let vc = segue.destinationViewController.childViewControllers[0] as? AddRefillTVC {
                    vc.med = self.med
                }
            }
            
            if segue.identifier == "viewDoseHistory" {
                if let vc = segue.destinationViewController as? MedicineDoseHistoryTVC {
                    vc.med = self.med
                }
            }
            
            if segue.identifier == "viewRefillHistory" {
                if let vc = segue.destinationViewController as? MedicineRefillHistoryTVC {
                    vc.med = self.med
                }
            }
        }
    }

}


private enum Rows: Int {
    case none = -1
    case name
    case nextDose
    case doseDetails
    case prescriptionCount
    case actions
    case doseHistory
    case refillHistory
    case delete
    
    init(index: NSIndexPath) {
        var row = Rows.none
        
        switch (index.section, index.row) {
        case (0, 0):
            row = Rows.name
        case (0, 1):
            row = Rows.nextDose
        case (0, 2):
            row = Rows.doseDetails
        case (0, 3):
            row = Rows.prescriptionCount
        case (1, 0):
            row = Rows.actions
        case (2, 0):
            row = Rows.doseHistory
        case (2, 1):
            row = Rows.refillHistory
        case (3, 0):
            row = Rows.delete
        default:
            row = Rows.none
        }
        
        self = row
    }
    
    func index() -> NSIndexPath {
        switch self {
        case .name:
            return NSIndexPath(forRow: 0, inSection: 0)
        case .nextDose:
            return NSIndexPath(forRow: 1, inSection: 0)
        case .doseDetails:
            return NSIndexPath(forRow: 2, inSection: 0)
        case .prescriptionCount:
            return NSIndexPath(forRow: 3, inSection: 0)
        case .actions:
            return NSIndexPath(forRow: 0, inSection: 1)
        case .doseHistory:
            return NSIndexPath(forRow: 0, inSection: 2)
        case .refillHistory:
            return NSIndexPath(forRow: 1, inSection: 2)
        case .delete:
            return NSIndexPath(forRow: 0, inSection: 3)
        default:
            return NSIndexPath(forRow: 0, inSection: 0)
        }
    }
}
