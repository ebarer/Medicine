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

    var gblCount = 0
    var medication = [Medicine]()
    var history = [History]()
    var log = [NSDate: [History]]()
    
    
    // MARK: - Helper variables
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext!
    
    let cal = NSCalendar.currentCalendar()
    let dateFormatter = NSDateFormatter()
    
    var editButtons = [UIBarButtonItem]()
    
    func getSectionDate(section: Int) -> NSDate {
        let unit = NSCalendarUnit.Day
        return cal.dateByAddingUnit(unit, value: -1 * section, toDate: cal.startOfDayForDate(NSDate()), options: [])!
    }
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Assign moc
        moc = appDelegate.managedObjectContext
        
        // Modify VC
        self.view.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        self.navigationController?.toolbar.translucent = true
        self.navigationController?.toolbar.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        // Configure edit toolbar buttons
        let deleteButton = UIBarButtonItem(title: "Delete", style: UIBarButtonItemStyle.Plain, target: self, action: "deleteDoses")
        deleteButton.enabled = false
        editButtons.append(deleteButton)
        setToolbarItems(editButtons, animated: true)
        
        // Add observeres for notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTableAndNotifications", name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        loadMedication()
        loadHistory()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadMedication()
        loadHistory()
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func loadHistory() {
        let request = NSFetchRequest(entityName:"History")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let fetchedResults = try moc.executeFetchRequest(request) as? [History]
            
            if let results = fetchedResults {
                history = results
                
                // Clear existing log
                log.removeAll()
                
                // Sort history
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

                gblCount = history.count
                displayEmptyView()
            }
        } catch {
            print("Could not fetch history.")
        }
    }
    
    func loadMedication() {
        let request = NSFetchRequest(entityName:"Medicine")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        
        do {
            let fetchedResults = try moc.executeFetchRequest(request) as? [Medicine]
            
            if let results = fetchedResults {
                medication = results
            }
        } catch {
            print("Could not fetch medication.")
        }
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if gblCount == 0 {
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
            dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle;
            dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle;
            
            cell.textLabel?.textColor = UIColor.blackColor()
            cell.textLabel?.text = dateFormatter.stringFromDate(history[indexPath.row].date)
            
            cell.detailTextLabel?.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
            cell.detailTextLabel?.text = history[indexPath.row].medicine?.name
            
            return cell
        }
        
        cell.textLabel?.textColor = UIColor.lightGrayColor()
        cell.textLabel?.text = "No doses logged"
        cell.detailTextLabel?.text?.removeAll()
        
        return cell
    }
    
    func refreshTableAndNotifications() {
        clearOldNotifications()
        tableView.reloadData()
    }
    
    func clearOldNotifications() {
        let currentDate = NSDate()
        let notifications = UIApplication.sharedApplication().scheduledLocalNotifications!
        for notification in notifications {
            if let date = notification.fireDate {
                if date.compare(currentDate) == .OrderedAscending {
                    UIApplication.sharedApplication().cancelLocalNotification(notification)
                }
            }
        }
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let sectionDate = getSectionDate(indexPath.section)
        
        if log[sectionDate]?.count == 0 {
            return false
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
            if let tBC = self.tabBarController {
                tBC.setTabBarVisible(false, animated: true)
                self.navigationController?.setToolbarHidden(false, animated: true)
            }
        } else {
            if let tBC = self.tabBarController {
                self.navigationController?.setToolbarHidden(true, animated: true)
                tBC.setTabBarVisible(true, animated: true)
            }
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
            let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
            for index in selectedRowIndexes.reverse() {
                let sectionDate = getSectionDate(index.section)
                
                if let logItems = log[sectionDate] {
                    if let med = logItems[index.row].medicine {
                        if med.lastDose == logItems[index.row] {
                            med.untakeLastDose(moc)
                        } else {
                            moc.deleteObject(logItems[index.row])
                        }
                    } else {
                        moc.deleteObject(logItems[index.row])
                    }
                    
                    delegate.saveContext()
                    
                    log[sectionDate]?.removeAtIndex(index.row)
                    gblCount--
                    
                    if logItems.count == 1 {
                        tableView.cellForRowAtIndexPath(index)
                        let label = tableView.cellForRowAtIndexPath(index)?.textLabel
                        let detail = tableView.cellForRowAtIndexPath(index)?.detailTextLabel
                        
                        label?.textColor = UIColor.lightGrayColor()
                        label?.text = "No doses logged"
                        detail?.text?.removeAll()
                    } else {
                        tableView.deleteRowsAtIndexPaths([index], withRowAnimation: .Fade)
                    }
                }
            }
            
            updateDeleteButtonLabel()
            setEditing(false, animated: true)
            
            if gblCount == 0 {
                displayEmptyView()
            }
        }
    }
    
    func displayEmptyView() {
        if gblCount == 0 {
            navigationItem.leftBarButtonItem?.enabled = false
            
            // Create empty message
            if medication.count == 0 {
                if let emptyView = UINib(nibName: "MainEmptyView", bundle: nil).instantiateWithOwner(self, options: nil)[0] as? UIView {
                    tableView.backgroundView = emptyView
                }
            } else {
                if let emptyView = UINib(nibName: "HistoryEmptyView", bundle: nil).instantiateWithOwner(self, options: nil)[0] as? UIView {
                    tableView.backgroundView = emptyView
                }
            }
        } else {
            navigationItem.leftBarButtonItem?.enabled = true
            tableView.backgroundView = nil
        }
        
        if medication.count == 0 {
            navigationItem.rightBarButtonItem?.enabled = false
        } else {
            navigationItem.rightBarButtonItem?.enabled = true
        }
        
        tableView.reloadData()
    }
    
    
    // MARK: - Navigation methods
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addDose" {
            if let vc = segue.destinationViewController.childViewControllers[0] as? AddDoseTVC {
                vc.globalHistory = true
            }
        }
    }
    
    
    // MARK: - Unwind methods
    
    @IBAction func historyUnwindAdd(unwindSegue: UIStoryboardSegue) {
        // Log dose
        let svc = unwindSegue.sourceViewController as! AddDoseTVC
        if let dose = svc.med?.addDose(moc, date: svc.date) {
            appDelegate.saveContext()
            
            gblCount++
            
            // Add to log
            let index = cal.startOfDayForDate(svc.date)
            log[index]?.insert(dose, atIndex: 0)
            log[index]?.sortInPlace({ $0.date.compare($1.date) == .OrderedDescending })
            
            // Reload table
            self.tableView.reloadData()
        }
    }
    
    @IBAction func unwindCancel(unwindSegue: UIStoryboardSegue) {}
    
}
