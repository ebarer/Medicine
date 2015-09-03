//
//  MainTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-27.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class MainTVC: UITableViewController {
    
    var medication = [Medicine]()
    
    
    // MARK: - Helper variables
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext!
    
    let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    let dateFormatter = NSDateFormatter()
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Modify VC
        self.view.tintColor = UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0)
        self.clearsSelectionOnViewWillAppear = false
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        // Modify table
        tableView.tableHeaderView = UIView(frame: CGRectMake(0.0, 0.0, tableView.bounds.size.width, 0.01))
        
        // Add observeres for notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "internalNotification:", name: "medNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "takeMedicationNotification:", name: "takeDoseNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "snoozeReminderNotification:", name: "snoozeReminderNotification", object: nil)
        
        // Cancel all notifications
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        // Load medications
        let request = NSFetchRequest(entityName:"Medicine")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        
        do {
            let fetchedResults = try moc.executeFetchRequest(request) as? [Medicine]
            
            if let results = fetchedResults {
                medication = results
                
                // Schedule all notifications
                for med in medication {
                    med.setNotification()
                }
            }
        } catch {
            print("Could not fetch medication.")
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(true, animated: true)
        
        // If no medications, display empty message
        displayEmptyView()
        
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("MainTVC")
    }

    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return medication.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100.0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("medicationCell", forIndexPath: indexPath)
        let med = medication[indexPath.row]
        
        // Set cell tint
        cell.tintColor = UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0)
        
        // Set medication name
        cell.textLabel?.text = med.name
        
        // Set medication subtitle to next dosage date
        if let date = med.nextDose {

            var dateString = String()

            if cal.isDate(date, inSameDayAsDate: NSDate()) {
                // If date is today
                dateFormatter.dateFormat = "h:mm a"
                dateString = dateFormatter.stringFromDate(date)
            } else if cal.isDateInTomorrow(date) {
                // If date is tomorrow
                dateFormatter.dateFormat = "h:mm a"
                dateString = "Tomorrow, " + dateFormatter.stringFromDate(date)
            } else if date.compare(cal.dateByAddingUnit(NSCalendarUnit.WeekOfYear, value: 1, toDate: cal.startOfDayForDate(NSDate()), options: [])!) == .OrderedAscending {
                // If date is within current week
                dateFormatter.dateFormat = "EEEE, h:mm a"
                dateString = dateFormatter.stringFromDate(date)
            } else {
                dateFormatter.dateFormat = "MMM d, h:mm a"
                dateString = dateFormatter.stringFromDate(date)
            }
            
            let subtitle = NSMutableAttributedString()

            if med.isOverdue {
                cell.textLabel?.textColor = UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0)
                
                subtitle.appendAttributedString(NSAttributedString(string: "Overdue: \(dateString)"))
                subtitle.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0), range: NSMakeRange(0, subtitle.length))
                subtitle.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFontOfSize(15.0), range: NSMakeRange(0, 8))
            } else {
                subtitle.appendAttributedString(NSAttributedString(string: "Next dose: \(dateString)"))
                subtitle.addAttribute(NSForegroundColorAttributeName, value: UIColor.lightGrayColor(), range: NSMakeRange(0, 10))
            }
            
            cell.detailTextLabel?.attributedText = subtitle
        } else {
            cell.detailTextLabel?.attributedText = NSAttributedString(string: "Tap to take next dose", attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        medication[fromIndexPath.row].sortOrder = Int16(toIndexPath.row)
        medication[toIndexPath.row].sortOrder = Int16(fromIndexPath.row)
        medication.sortInPlace({ $0.sortOrder < $1.sortOrder })
        appDelegate.saveContext()
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if let name = medication[indexPath.row].name {
                self.presentDeleteAlert(name, indexPath: indexPath)
            }
        }
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let med = medication[indexPath.row]
        
        if (tableView.editing == false) {
            let alert = UIAlertController(title: med.name, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            alert.addAction(UIAlertAction(title: "Take Next Dose", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
                // TODO: Handle false by displaying error "Medication already taken within last 5 minutes. If error, untake last dose."
                if (med.takeNextDose(self.moc)) {
                    self.appDelegate.saveContext()
                    tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                } else {
                    tableView.deselectRowAtIndexPath(indexPath, animated: true)
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Log Previous Dose", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
                self.performSegueWithIdentifier("addDose", sender: self)
            }))
            
            // If next dosage is set, allow user to clear notification
            if (med.nextDose != nil) {
                alert.addAction(UIAlertAction(title: "Undo Last Dose", style: .Destructive, handler: {(action) -> Void in
                    if (med.untakeLastDose(self.moc)) {
                        self.appDelegate.saveContext()
                        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                    } else {
                        tableView.deselectRowAtIndexPath(indexPath, animated: true)
                    }
                }))
            }
            
            
            alert.addAction(UIAlertAction(title: "Edit", style: .Default, handler: {(action) -> Void in
                self.performSegueWithIdentifier("editMedication", sender: indexPath.row)
            }))
            
            alert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: {(action) -> Void in
                if let name = med.name {
                    self.presentDeleteAlert(name, indexPath: indexPath)
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: {(action) -> Void in
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }))

            alert.view.tintColor = UIColor.grayColor()
            presentViewController(alert, animated: true, completion: nil)
        } else {
            performSegueWithIdentifier("editMedication", sender: indexPath.row)
        }
    }
    
    
    // MARK: - Delete functions
    
    func presentDeleteAlert(name: String, indexPath: NSIndexPath) {
        let deleteAlert = UIAlertController(title: "Delete \"\(name)\"?", message: "This will permanently delete the \"\(name)\" medication and all of its history.", preferredStyle: UIAlertControllerStyle.Alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {(action) -> Void in
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: {(action) -> Void in
            self.deleteMed(indexPath)
        }))
        
        self.presentViewController(deleteAlert, animated: true, completion: nil)
    }
    
    func deleteMed(indexPath: NSIndexPath) {
        // Cancel all notifications for medication
        medication[indexPath.row].cancelNotification()
        
        // Remove medication from persistent store
        moc.deleteObject(medication[indexPath.row])
        appDelegate.saveContext()
        
        // Remove medication from array
        medication.removeAtIndex(indexPath.row)
        
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        tableView.editing = false
        
        displayEmptyView()
    }
    
    func displayEmptyView() {
        if medication.count == 0 {
            self.navigationItem.leftBarButtonItem?.enabled = false
            
            // Create empty message
            if let emptyView = UINib(nibName: "MainEmptyView", bundle: nil).instantiateWithOwner(self, options: nil)[0] as? UIView {
                // Display message
                self.tableView.backgroundView = emptyView
            }
        } else {
            self.navigationItem.leftBarButtonItem?.enabled = true
            self.tableView.backgroundView = nil
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addMedication" {
            let entity = NSEntityDescription.entityForName("Medicine", inManagedObjectContext: moc)
            let temp = Medicine(entity: entity!, insertIntoManagedObjectContext: moc)
            
            let vc = segue.destinationViewController as! UINavigationController
            let addVC = vc.topViewController as! AddMedicationTVC
            addVC.title = "New Medication"
            addVC.med = temp
        }
        
        if segue.identifier == "editMedication" {
            let vc = segue.destinationViewController as! UINavigationController
            let addVC = vc.topViewController as! AddMedicationTVC
            addVC.title = "Edit Medication"
            addVC.med = medication[sender as! Int]
            addVC.editMode = true
        }
        
        if segue.identifier == "viewMedicationDetails" {
            let vc = segue.destinationViewController as! HistoryTVC
            if let index = self.tableView.indexPathForCell(sender as! UITableViewCell) {
                vc.med = medication[index.row]
                vc.moc = self.moc
            }
        }
    }
    
    
    // MARK: - Unwind methods
    
    @IBAction func medicationUnwindAdd(unwindSegue: UIStoryboardSegue) {
        if let svc = unwindSegue.sourceViewController as? AddMedicationTVC, addMed = svc.med {
            if let selectedIndex = tableView.indexPathForSelectedRow {
                appDelegate.saveContext()
                
                tableView.reloadRowsAtIndexPaths([selectedIndex], withRowAnimation: .None)
            } else {
                let newIndex = NSIndexPath(forRow: medication.count, inSection: 0)
                
                addMed.sortOrder = Int16(newIndex.row)
                medication.append(addMed)
                appDelegate.saveContext()
                
                tableView.insertRowsAtIndexPaths([newIndex], withRowAnimation: .Bottom)
            }
        }
    }
    
    @IBAction func medicationUnwindCancel(unwindSegue: UIStoryboardSegue) {
        moc.rollback()
        self.tableView.reloadData()
    }
    
    @IBAction func historyUnwindAdd(unwindSegue: UIStoryboardSegue) {
        if let selectedIndex = tableView.indexPathForSelectedRow {
            // Log dose
            let svc = unwindSegue.sourceViewController as! AddDoseTVC
            let entity = NSEntityDescription.entityForName("History", inManagedObjectContext: moc)
            let newDose = History(entity: entity!, insertIntoManagedObjectContext: moc)
            let med = medication[selectedIndex.row]
            newDose.medicine = med
            newDose.date = svc.date
            appDelegate.saveContext()
            
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
    }
    
    @IBAction func historyUnwindCancel(unwindSegue: UIStoryboardSegue) {}
    
    
    // MARK: - Local Notifications
    
    func internalNotification(notification: NSNotification) {
        if let id = notification.userInfo!["id"] as? String {
            let medQuery = medication.filter{ $0.medicineID == id }.first
            if let med = medQuery {
                if let name = med.name {
                    let message = String(format:"Time to take %g %@ of %@", med.dosage, med.dosageUnit.units(med.dosage), name)
                    
                    let alert = UIAlertController(title: "Take \(name)", message: message, preferredStyle: .Alert)
                    
                    alert.addAction(UIAlertAction(title: "Take Dose", style: .Default, handler: {(action) -> Void in
                        self.takeMedicationNotification(notification)
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Snooze", style: .Cancel, handler: {(action) -> Void in
                        self.snoozeReminderNotification(notification)
                    }))
                    
                    alert.view.tintColor = UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0)
                    
                    // TODO: Don't display if not front most VC
                    presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func takeMedicationNotification(notification: NSNotification) {
        if let id = notification.userInfo!["id"] as? String {
            let medQuery = medication.filter{ $0.medicineID == id }.first
            if let med = medQuery {
                if (med.takeNextDose(self.moc)) {
                    self.appDelegate.saveContext()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func snoozeReminderNotification(notification: NSNotification) {
        if let info = notification.userInfo {
            if let id = info["id"] as? String {
                let medQuery = medication.filter{ $0.medicineID == id }.first
                if let med = medQuery {
                    med.snoozeNotification()
                    appDelegate.saveContext()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
}
