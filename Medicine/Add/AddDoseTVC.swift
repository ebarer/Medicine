//
//  HistoryAddTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-31.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class AddDoseTVC: UITableViewController {
    
    var med:Medicine?
    var globalHistory: Bool = false
    var date = NSDate()
    let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    
    // MARK: - Outlets
    
    @IBOutlet var medLabel: UILabel!
    @IBOutlet var picker: UIDatePicker!
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        
        // Set medicine label
        if let med = med {
            medLabel.text = med.name
            self.navigationItem.rightBarButtonItem?.enabled = true
        } else {
            medLabel.text = "None"
            self.navigationItem.rightBarButtonItem?.enabled = false
        }
        
        // Set picker min/max values
        picker.maximumDate = NSDate()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func updateDate(sender: UIDatePicker) {
        date = sender.date
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch(indexPath) {
        case NSIndexPath(forRow: 0, inSection: 0):
            if globalHistory {
                return tableView.rowHeight
            } else {
                return 0.0
            }
        case NSIndexPath(forRow: 1, inSection: 0):
            return 216.0
        default:
            return tableView.rowHeight
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? AddDoseTV_Medicine {
            vc.selectedMed = med
        }
    }
    
    @IBAction func medicationUnwindSelect(unwindSegue: UIStoryboardSegue) {
        if let svc = unwindSegue.sourceViewController as? AddDoseTV_Medicine, selectedMed = svc.selectedMed {
            med = selectedMed
            medLabel.text = selectedMed.name
            self.navigationItem.rightBarButtonItem?.enabled = true
        }
    }

}