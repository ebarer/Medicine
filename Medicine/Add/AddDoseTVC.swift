//
//  HistoryAddTVC.swift
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
        
        // Display med name in prompt when not in global history
        if let name = med?.name where !globalHistory {
            self.navigationItem.prompt = name
        }
        
        updateLabels()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateLabels() {
        // Set medicine label
        if let med = med {
            medLabel.text = med.name
            doseLabel.text = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
            self.navigationItem.rightBarButtonItem?.enabled = true
        } else {
            if let med = medication.first {
                self.med = med
                medLabel.text = med.name
                doseLabel.text = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
                self.navigationItem.rightBarButtonItem?.enabled = true
            } else {
                medLabel.text = "None"
                doseLabel.text = "None"
                self.navigationItem.rightBarButtonItem?.enabled = false
            }
        }
    }
    
    @IBAction func updateDate(sender: UIDatePicker) {
        date = sender.date
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch(indexPath) {
        case NSIndexPath(forRow: 0, inSection: 1):
            if globalHistory {
                return tableView.rowHeight
            } else {
                return 0.0
            }
        case NSIndexPath(forRow: 0, inSection: 0):
            return 216.0
        default:
            return tableView.rowHeight
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? AddDoseTVC_Medicine {
            vc.selectedMed = med
        }
        
        if let vc = segue.destinationViewController as? AddMedicationTVC_Dosage {
            vc.med = med
            
            // Display med name in prompt when not in global history
            if let name = med?.name where !globalHistory {
                vc.navigationItem.prompt = name
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

}