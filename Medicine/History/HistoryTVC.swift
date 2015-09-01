//
//  HistoryTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-28.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class HistoryTVC: UITableViewController {
    
    weak var med:Medicine!
    var log = [NSDate:[History]]()
    
    
    // MARK: - Helper variables
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext!
    
    let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    let dateFormatter = NSDateFormatter()
    
    var normalButtons = [UIBarButtonItem]()
    var editButtons = [UIBarButtonItem]()
    
    func getSectionDate(section: Int) -> NSDate {
        return cal.dateByAddingUnit(NSCalendarUnit.Day, value: -1 * section, toDate: cal.startOfDayForDate(NSDate()), options: [])!
    }
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Modify VC
        self.view.tintColor = UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0)
        self.navigationController?.toolbar.tintColor = UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0)
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Configure toolbar buttons
        let fixedButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        normalButtons.append(fixedButton)
        
        let addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "addDose")
        normalButtons.append(addButton)

        let deleteButton = UIBarButtonItem(title: "Delete", style: UIBarButtonItemStyle.Plain, target: self, action: "deleteDoses")
        deleteButton.enabled = false
        editButtons.append(deleteButton)
        
        setToolbarItems(normalButtons, animated: true)
        
        // Sort history
        if let historySet = med.history {
            let history = historySet.array as! [History]
            for index in 0...6 {
                let sectionDate = getSectionDate(index)
                
                // Initialize date log
                log[sectionDate] = [History]()
                
                // Store history in log
                for dose in history {
                    if (cal.isDate(dose.date, inSameDayAsDate: sectionDate)) {
                        log[sectionDate]?.insert(dose, atIndex: 0)
                    }
                }
                
                // Sort each log date
                log[sectionDate]?.sortInPlace({ $0.date.compare($1.date) == .OrderedDescending })
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: true)
        self.navigationController?.toolbar.translucent = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("HistoryVC")
    }
    
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 7
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionDate = getSectionDate(section)
        if let count = log[sectionDate]?.count {
            return count
        }
        
        return 0;
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionDate = getSectionDate(section)
        
        // Special header for today/yesterday
        if (section == 0) {
            dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle;
            dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle;
            return "Today, \(dateFormatter.stringFromDate(sectionDate))"
        } else if (section == 1) {
            return "Yesterday"
        }
        
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.stringFromDate(sectionDate)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("historyCell", forIndexPath: indexPath)
        let sectionDate = getSectionDate(indexPath.section)

        if let history = log[sectionDate] {
            dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle;
            dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle;
                
            cell.textLabel?.text = dateFormatter.stringFromDate(history[indexPath.row].date)
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let sectionDate = getSectionDate(indexPath.section)
        
        if let logItems = log[sectionDate] {
            if logItems[indexPath.row] == med.lastDose {
                med.untakeLastDose(moc)
            } else {
                moc.deleteObject(logItems[indexPath.row])
            }
            
            log[sectionDate]?.removeAtIndex(indexPath.row)
            appDelegate.saveContext()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        updateDeleteButtonLabel()
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        updateDeleteButtonLabel()
    }
    
    
    // MARK: - Toolbar methods
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing == true {
            setToolbarItems(editButtons, animated: true)
        } else {
            setToolbarItems(normalButtons, animated: true)
        }
    }
    
    func updateDeleteButtonLabel() {
        if let selectedRows = tableView.indexPathsForSelectedRows {
            editButtons[0].title = "Delete (\(selectedRows.count))"
            editButtons[0].enabled = true
        } else {
            editButtons[0].title = "Delete"
            editButtons[0].enabled = false
        }
    }
    
    func addDose() {
        performSegueWithIdentifier("addDose", sender: self)
    }
    
    func deleteDoses() {
        if let selectedRowIndexes = tableView.indexPathsForSelectedRows {
            for index in selectedRowIndexes.reverse() {                
                let sectionDate = getSectionDate(index.section)
                
                if let logItems = log[sectionDate] {
                    if logItems[index.row] == med.lastDose {
                        med.untakeLastDose(moc)
                    } else {
                        moc.deleteObject(logItems[index.row])
                    }
                    
                    log[sectionDate]?.removeAtIndex(index.row)
                }
            }
            
            appDelegate.saveContext()
            
            tableView.deleteRowsAtIndexPaths(selectedRowIndexes, withRowAnimation: .Fade)
            
            updateDeleteButtonLabel()
            setEditing(false, animated: true)
        }
    }
    
    
    // MARK: - Unwind methods
    
    @IBAction func historyUnwindAdd(unwindSegue: UIStoryboardSegue) {
        // Log dose
        let svc = unwindSegue.sourceViewController as! AddDoseTVC
        let entity = NSEntityDescription.entityForName("History", inManagedObjectContext: moc)
        let newDose = History(entity: entity!, insertIntoManagedObjectContext: moc)
        newDose.medicine = med
        newDose.date = svc.date
        appDelegate.saveContext()
        
        // Add to log
        let index = cal.startOfDayForDate(svc.date)
        log[index]?.insert(newDose, atIndex: 0)
        log[index]?.sortInPlace({ $0.date.compare($1.date) == .OrderedDescending })
        
        // Reschedule notification if newest addition
        if let date = med.lastDose?.date {
            if (newDose.date.compare(date) == .OrderedDescending || newDose.date.compare(date) == .OrderedSame) {
                med.cancelNotification()
                med.setNotification()
            }
        }
        
        // Reload table
        self.tableView.reloadData()
    }
    
    @IBAction func historyUnwindCancel(unwindSegue: UIStoryboardSegue) {}

}
