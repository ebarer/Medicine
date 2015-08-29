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

    var med:Medicine!
    var log = [NSDate:[History]]()
    
    // MARK: - Helper variables
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext!
    
    let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    let dateFormatter = NSDateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Customize navigation bar
        self.title = "\(med.name!) History"
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Sort history
        let history = med.history?.array as! [History]
        for index in 0...6 {
            let sectionDate = printSectionDate(index)
            
            log[sectionDate] = [History]()
            
            for dose in history {
                if (cal.isDate(dose.date, inSameDayAsDate: sectionDate)) {
                    log[sectionDate]?.insert(dose, atIndex: 0)
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 7
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionDate = printSectionDate(section)
        if let count = log[sectionDate]?.count {
            return count
        }
        
        return 0;
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionDate = printSectionDate(section)
        
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
        let sectionDate = printSectionDate(indexPath.section)

        if let history = log[sectionDate] {
            dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle;
            dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle;
                
            cell.textLabel?.text = dateFormatter.stringFromDate(history[indexPath.row].date)
        }

        return cell
    }
    
    
    // MARK: - Table view delegate

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let sectionDate = printSectionDate(indexPath.section)
        
        if editingStyle == .Delete {
            if let history = log[sectionDate] {
                // If deleting most recent dose, reschedule notification
                if (history[indexPath.row] == (med.history?.lastObject as! History)) {
                    med.untakeLastDose(moc)
                } else {
                    moc.deleteObject(history[indexPath.row])
                }
                
                appDelegate.saveContext()
                log[sectionDate]?.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
        }
    }
    
    @IBAction func historyUnwindAdd(unwindSegue: UIStoryboardSegue) {
        // Log dose
        let svc = unwindSegue.sourceViewController as! HistoryAddVC
        let entity = NSEntityDescription.entityForName("History", inManagedObjectContext: moc)
        let newDose = History(entity: entity!, insertIntoManagedObjectContext: moc)
        newDose.medicine = med
        newDose.date = svc.date
        appDelegate.saveContext()
        
        // Add to log
        let index = cal.startOfDayForDate(svc.date)
        log[index]?.insert(newDose, atIndex: 0)
        log[index]?.sortInPlace({ $0.date.compare($1.date) == NSComparisonResult.OrderedDescending })
        
        // Reload table
        self.tableView.reloadData()
    }
    
    @IBAction func historyUnwindCancel(unwindSegue: UIStoryboardSegue) {
        // let svc = unwindSegue.sourceViewController as! AddMedicationTVC
    }
    
    @IBAction func logDose(sender: AnyObject) {
        print("logging history for \(med.name!)")
    }
    
    func printSectionDate(section: Int) -> NSDate {
        return cal.dateByAddingUnit(NSCalendarUnit.Day, value: -1 * section, toDate: cal.startOfDayForDate(NSDate()), options: [])!
    }

}
