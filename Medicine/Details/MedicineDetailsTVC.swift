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
    
    weak var med:Medicine!
    
    
    // MARK: - Outlets
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var prescriptionLabel: UILabel!
    
    
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect selected row
        if let index = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(index, animated: animated)
        }
        
        self.navigationController?.setToolbarHidden(true, animated: animated)
        
        updateLabels()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateLabels() {
        nameLabel.text = med.name
        
        if med.prescriptionCount.isNormal {
            prescriptionLabel.text = "\(med.removeTrailingZero(med.prescriptionCount)) \(med.dosageUnit.units(med.prescriptionCount))"
        } else {
            prescriptionLabel.text = "None"
        }
    }
    
    
    // MARK: - Table view delegates
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath == NSIndexPath(forRow: 0, inSection: 1) {
            presentDeleteAlert(indexPath)
        }
    }


    // MARK: - Actions
    
    func editMedication() {
        performSegueWithIdentifier("editMedication", sender: nil)
    }
    
    func presentDeleteAlert(indexPath: NSIndexPath) {
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
    }
    
    func deleteMed() {
        // Cancel all notifications for medication
        med.cancelNotification()
        
        // Remove medication from array
        medication.removeObject(med)
        
        // Remove medication from persistent store
        moc.deleteObject(med)
        appDelegate.saveContext()

        NSNotificationCenter.defaultCenter().postNotificationName("refreshMedication", object: nil, userInfo: nil)
        
        // Dismiss view
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        self.navigationItem.backBarButtonItem?.title = med.name
        
        if segue.identifier == "editMedication" {
            if let vc = segue.destinationViewController.childViewControllers[0] as? AddMedicationTVC {
                vc.med = self.med
                vc.editMode = true
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
