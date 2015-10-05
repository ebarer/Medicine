//
//  MedicineDetailsTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-28.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class MedicineDetailsTVC: UITableViewController {
    
    weak var med:Medicine!
    var count = 0
    var log = [NSDate: [History]]()
    
    
    // MARK: - Helper variables
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext!
    
    let cal = NSCalendar.currentCalendar()
    let dateFormatter = NSDateFormatter()
    
    var normalButtons = [UIBarButtonItem]()
    var editButtons = [UIBarButtonItem]()
    
    func getSectionDate(section: Int) -> NSDate {
        var unit = NSCalendarUnit.Day
        
        if med.intervalUnit == Intervals.Weekly {
            unit = NSCalendarUnit.WeekOfYear
        }
        
        return cal.dateByAddingUnit(unit, value: -1 * section, toDate: cal.startOfDayForDate(NSDate()), options: [])!
    }
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Modify VC
        if let name = med.name {
            self.title = "\(name) History"
        }
        
        self.view.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        self.navigationController?.toolbar.translucent = true
        self.navigationController?.toolbar.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        
        // Configure toolbar buttons
        let fixedButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let deleteButton = UIBarButtonItem(title: "Delete", style: UIBarButtonItemStyle.Plain, target: self, action: "deleteDoses")
        deleteButton.enabled = false
        
        normalButtons.append(fixedButton)
        normalButtons.append(self.editButtonItem())
        
        editButtons.append(deleteButton)
        editButtons.append(fixedButton)
        editButtons.append(self.editButtonItem())

        setToolbarItems(normalButtons, animated: false)
        
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
            
            count = history.count
            displayEmptyView()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        displayEmptyView()
        tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.navigationController?.setToolbarHidden(false, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if count == 0 {
            return 0
        }
        
        return 7
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionDate = getSectionDate(section)
        
        if let count = log[sectionDate]?.count {
            // Handle dates with no logged items
            if count == 0 {
                return 1
            }
            
            return count
        }
        
        return 0;
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionDate = getSectionDate(section)
        
        // Special headers for today/yesterday
        if (section == 0) {
            dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle;
            dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle;
            return "Today (\(dateFormatter.stringFromDate(sectionDate)))"
        }
        
        if sectionDate.isDateInLastWeek() {
            if cal.isDateInYesterday(sectionDate) {
                return "Yesterday"
            }
            
            dateFormatter.dateFormat = "EEEE"
            return dateFormatter.stringFromDate(sectionDate)
        } else {
            dateFormatter.dateFormat = "MMM d"
            return dateFormatter.stringFromDate(sectionDate)
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let sectionDate = getSectionDate(indexPath.section)
        
        if let history = log[sectionDate] where history.count > 0 {
            return 55.0
        }
        
        return tableView.rowHeight
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {        
        let cell = tableView.dequeueReusableCellWithIdentifier("historyCell", forIndexPath: indexPath)
        let sectionDate = getSectionDate(indexPath.section)
        
        // Specify selection color
        cell.selectedBackgroundView = UIView()
        
        if let history = log[sectionDate] where history.count > 0 {
            let dose = history[indexPath.row]
            
            dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle;
            dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle;
            
            cell.textLabel?.textColor = UIColor.blackColor()
            cell.textLabel?.text = dateFormatter.stringFromDate(history[indexPath.row].date)
            
            cell.detailTextLabel?.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
            cell.detailTextLabel?.text = String(format:"%g %@", dose.dosage, med.dosageUnit.units(dose.dosage))
            
            return cell
        }
        
        cell.textLabel?.textColor = UIColor.lightGrayColor()
        cell.textLabel?.text = "No doses logged"
        cell.detailTextLabel?.text?.removeAll()
        
        return cell
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let sectionDate = getSectionDate(indexPath.section)
        
        if log[sectionDate]?.count == 0 {
//            return false
        }
        
        return true
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let sectionDate = getSectionDate(indexPath.section)
        
        if log[sectionDate]?.count == 0 {
            return false
        }
        
        return true
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
            count--
            
            if logItems.count == 1 {
                if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                    cell.textLabel?.text = "No doses logged"
                    cell.textLabel?.textColor = UIColor.lightGrayColor()
                    tableView.editing = false
                }
            } else {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            
            appDelegate.saveContext()
        }
    }
    
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
    
    @IBAction func addDose() {
        performSegueWithIdentifier("addDose", sender: self)
    }
    
    func deleteDoses() {
        if let selectedRowIndexes = tableView.indexPathsForSelectedRows {
            for index in selectedRowIndexes.reverse() {                
                let sectionDate = getSectionDate(index.section)
                
                if let logItems = log[sectionDate] {
                    if let med = logItems[safe: index.row]?.medicine {
                        if med.lastDose == logItems[index.row] {
                            med.untakeLastDose(moc)
                        } else {
                            moc.deleteObject(logItems[index.row])
                        }
                    } else {
                        moc.deleteObject(logItems[index.row])
                    }
                    
                    appDelegate.saveContext()
                    
                    log[sectionDate]?.removeAtIndex(index.row)
                    count--
                    
                    if logItems.count == 1 {
                        let label = tableView.cellForRowAtIndexPath(index)?.textLabel

                        label?.textColor = UIColor.lightGrayColor()
                        label?.text = "No doses logged"
                    } else {
                        tableView.deleteRowsAtIndexPaths([index], withRowAnimation: .Fade)
                    }
                }
            }
            
            updateDeleteButtonLabel()
            setEditing(false, animated: true)

            if count == 0 {
                displayEmptyView()
            }
        }
    }
    
    func displayEmptyView() {
        if count == 0 {
            self.editButtonItem().enabled = false
            
            // Create empty message
            if let emptyView = UINib(nibName: "HistoryEmptyView", bundle: nil).instantiateWithOwner(self, options: nil)[0] as? UIView {
                tableView.backgroundView = emptyView
            }
        } else {
            self.editButtonItem().enabled = true
            tableView.backgroundView = nil
        }
        
        tableView.reloadData()
    }
    
    
    // MARK: - Navigation methods
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addDose" {
            if let vc = segue.destinationViewController.childViewControllers[0] as? AddDoseTVC {
                vc.med = med
            }
        }
    }
    
    
    // MARK: - Preview actions
    
//    @available(iOS 9.0, *)
//    override func previewActionItems() -> [UIPreviewActionItem] {
//        return previewActions
//    }
//    
//    @available(iOS 9.0, *)
//    lazy var previewActions: [UIPreviewActionItem] = {
//        func previewActionForTitle(title: String, style: UIPreviewActionStyle = .Default) -> UIPreviewAction {
//            return UIPreviewAction(title: title, style: style) { previewAction, viewController in
//                guard let vc = viewController as? MedicineDetailsTVC else { return }
//                vc.performSegueWithIdentifier("addDose", sender: nil)
//                return
//            }
//        }
//        
//        let action1 = previewActionForTitle("Take Dose")
//        return [action1]
//    }()

    
    // MARK: - Unwind methods
    
    @IBAction func historyUnwindAdd(unwindSegue: UIStoryboardSegue) {
        // Log dose
        let svc = unwindSegue.sourceViewController as! AddDoseTVC
        let dose = med.addDose(moc, date: svc.date)
        
        appDelegate.saveContext()
        
        // Add to log
        let index = cal.startOfDayForDate(svc.date)
        log[index]?.insert(dose, atIndex: 0)
        log[index]?.sortInPlace({ $0.date.compare($1.date) == .OrderedDescending })
        count++
        
        // Reload table
        self.tableView.reloadData()
    }
    
    @IBAction func unwindCancel(unwindSegue: UIStoryboardSegue) {}

}
