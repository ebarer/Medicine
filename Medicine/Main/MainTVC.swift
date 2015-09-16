//
//  MainTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-27.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData
import StoreKit

class MainTVC: UITableViewController, SKPaymentTransactionObserver {
    
    var medication = [Medicine]()
    
    
    // MARK: - Outlets
    
    @IBOutlet var addMedicationButton: UIBarButtonItem!
    @IBOutlet var summaryHeader: UIView!
    @IBOutlet var headerDescriptionLabel: UILabel!
    @IBOutlet var headerCounterLabel: UILabel!
    @IBOutlet var headerMedLabel: UILabel!
    
    // MARK: - Helper variables
    
    let defaults = NSUserDefaults.standardUserDefaults()
    let productID = "com.ebarer.Medicine.Unlock"
    var mvc: UpgradeVC?
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext!
    
    let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    let dateFormatter = NSDateFormatter()
    
    
    // MARK: - IAP variables

    let trialLimit = 2
    var productLock = true
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup IAP
        if defaults.boolForKey("managerUnlocked") {
            productLock = false
        } else {
            productLock = true
        }
        
        // Modify VC tint and Navigation Item
        self.view.tintColor = UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0)
        self.clearsSelectionOnViewWillAppear = false
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        // Remove tableView gap
        tableView.tableHeaderView = UIView(frame: CGRectMake(0.0, 0.0, tableView.bounds.size.width, 0.01))
        
        // Add observeres for notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "internalNotification:", name: "medNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "takeMedicationNotification:", name: "takeDoseNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "snoozeReminderNotification:", name: "snoozeReminderNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTableAndNotifications", name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        // Cancel all existing notifications
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
                    med.scheduleNextNotification()
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
        
        // Print all scheduled notifications
        printNotifications()
        
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Memory Warning: MainTVC")
    }

    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    // Create summary header
    
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
        if let date = med.printNext() {

            var dateString = String()

            // Set label date, skip if date is today
            if !cal.isDateInToday(date) {
                if cal.isDateInYesterday(date) {
                    dateString = "Yesterday, "
                } else if cal.isDateInTomorrow(date) {
                    dateString = "Tomorrow, "
                } else if date.isDateInWeek() {
                    dateFormatter.dateFormat = "EEEE, "
                    dateString = dateFormatter.stringFromDate(date)
                } else {
                    // Default case
                    dateFormatter.dateFormat = "MMM d, "
                    dateString = dateFormatter.stringFromDate(date)
                }
            }
            
            // Set label time
            if date.isMidnight() {
                dateString.appendContentsOf("Midnight")
            } else {
                dateFormatter.dateFormat = "h:mm a"
                dateString.appendContentsOf(dateFormatter.stringFromDate(date))
            }
            
            let subtitle = NSMutableAttributedString()

            if med.isOverdue() {
                cell.textLabel?.textColor = UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0)
                
                subtitle.appendAttributedString(NSAttributedString(string: "Overdue: \(dateString)"))
                subtitle.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0), range: NSMakeRange(0, subtitle.length))
                subtitle.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFontOfSize(15.0), range: NSMakeRange(0, 8))
            } else {
                cell.textLabel?.textColor = UIColor.blackColor()
                subtitle.appendAttributedString(NSAttributedString(string: "Next dose: \(dateString)"))
                subtitle.addAttribute(NSForegroundColorAttributeName, value: UIColor.lightGrayColor(), range: NSMakeRange(0, 10))
            }
            
            cell.detailTextLabel?.attributedText = subtitle
        } else {
            cell.textLabel?.textColor = UIColor.blackColor()
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
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    // Empty implementation required for backwards compatibility (iOS 8.x)
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {}
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let editAction = UITableViewRowAction(style: .Default, title: "Edit") { (action, indexPath) -> Void in
            self.performSegueWithIdentifier("editMedication", sender: indexPath.row)
            self.tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
        }
        
        editAction.backgroundColor = UIColor(white: 0.78, alpha: 1.0)
        
        let deleteAction = UITableViewRowAction(style: .Destructive, title: "Delete") { (action, indexPath) -> Void in
            if let name = self.medication[indexPath.row].name {
                self.presentDeleteAlert(name, indexPath: indexPath)
            }
        }
        
        return [deleteAction, editAction]
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Setup summary header
        if section == 0 {
            if medication.count == 0 {
                return 0.0
            } else {
                return 150.0
            }
        }
        
        return 0.0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Create background gradient
        let colorTop = UIColor(white: 0.25, alpha: 1.0)
        let colorBottom = UIColor(red: 86.0/255, green: 32.0/255, blue: 34.0/255, alpha: 1.0).CGColor    // Light
        
        let gl = CAGradientLayer()
        gl.colors = [colorTop, colorBottom]
        gl.locations = [0.0, 1.0]
        gl.frame = summaryHeader.bounds
            
        summaryHeader.layer.insertSublayer(gl, atIndex: 0)
        
        // Setup summary labels
        var string = NSMutableAttributedString(string: "No more doses today")
        string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))
        headerCounterLabel.attributedText = string
        headerDescriptionLabel.text = nil
        headerMedLabel.text = nil
        
        // If we have overdue doses or an upcoming scheduled dose today, modify labels
        let overdueItems = medication.filter({$0.isOverdue()}).count
        if overdueItems > 0  {
            var text = "Overdue dose"

            // Pluralize string if multiple overdue doses
            if overdueItems > 1 {
                text += "s"
            }
            
            string = NSMutableAttributedString(string: text)
            string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))
            headerCounterLabel.attributedText = string
        } else if let nextDose = UIApplication.sharedApplication().scheduledLocalNotifications?.first {
            if cal.isDateInToday(nextDose.fireDate!) {
                if let id = nextDose.userInfo?["id"] {
                    if let med = Medicine.getMedicine(arr: medication, id: id as! String) {
                        headerDescriptionLabel.text = "Next Dose"
                        
                        // let dif = cal.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: NSDate(), toDate: nextDose.fireDate!, options: [])
                        dateFormatter.dateFormat = "h:mma"
                        
                        string = NSMutableAttributedString(string: dateFormatter.stringFromDate(nextDose.fireDate!))
                        let len = string.length
                        // string.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0), range: NSMakeRange(0, 2))
                        string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(70.0, weight: UIFontWeightUltraLight), range: NSMakeRange(0, len-2))
                        string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0), range: NSMakeRange(len-2, 2))
                        headerCounterLabel.attributedText = string
                        
                        let dose = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
                        headerMedLabel.text = "\(dose) of \(med.name!)"
                    }
                }
            }
        }
    
        return summaryHeader
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let med = medication[indexPath.row]
        
        if (tableView.editing == false) {
            var dateString:String? = nil
            
            // Format string for previous dose
            if let date = med.lastDose?.date {
                dateString = "Last Dose: "
                
                // Set label date, skip if date is today
                if cal.isDateInToday(date) {
                    dateString?.appendContentsOf("Today, ")
                } else if cal.isDateInYesterday(date) {
                    dateString?.appendContentsOf("Yesterday, ")
                } else if date.isDateInWeek() {
                    dateFormatter.dateFormat = "EEEE, "
                    dateString?.appendContentsOf(dateFormatter.stringFromDate(date))
                } else {
                    dateFormatter.dateFormat = "MMM d, "
                    dateString?.appendContentsOf(dateFormatter.stringFromDate(date))
                }
                
                // Set label time
                if date.isMidnight() {
                    dateString?.appendContentsOf("Midnight")
                } else {
                    dateFormatter.dateFormat = "h:mm a"
                    dateString?.appendContentsOf(dateFormatter.stringFromDate(date))
                }
            }
            
            let alert = UIAlertController(title: med.name, message: dateString, preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            alert.addAction(UIAlertAction(title: "Take Dose", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
                self.performSegueWithIdentifier("addDose", sender: self)
            }))
            
            // If next dosage is set, allow user to clear notification
            if (med.nextDose != nil) {
                alert.addAction(UIAlertAction(title: "Undo Last Dose", style: .Destructive, handler: {(action) -> Void in
                    if (med.untakeLastDose(self.moc)) {
                        self.appDelegate.saveContext()
                        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.None)
                        self.printNotifications()
                    } else {
                        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                    }
                }))
            }
            
//            alert.addAction(UIAlertAction(title: "Edit", style: .Default, handler: {(action) -> Void in
//                self.performSegueWithIdentifier("editMedication", sender: indexPath.row)
//            }))
            
            alert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: {(action) -> Void in
                if let name = med.name {
                    self.presentDeleteAlert(name, indexPath: indexPath)
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: {(action) -> Void in
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }))

            alert.view.tintColor = UIColor.grayColor()
            presentViewController(alert, animated: true, completion: nil)
        } else {
            performSegueWithIdentifier("editMedication", sender: indexPath.row)
        }
    }
    
    
    // MARK: - Delete methods
    
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

        if medication.count == 0 {
            displayEmptyView()
        } else {
            // tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        }
        
        printNotifications()
    }
    
    func displayEmptyView() {
        if medication.count == 0 {
            navigationItem.leftBarButtonItem?.enabled = false
            
            // Create empty message
            if let emptyView = UINib(nibName: "MainEmptyView", bundle: nil).instantiateWithOwner(self, options: nil)[0] as? UIView {
                // Display message
                tableView.backgroundView = emptyView
            }
        } else {
            navigationItem.leftBarButtonItem?.enabled = true
            tableView.backgroundView = nil
        }
        
        tableView.reloadData()
    }
    
    
    // MARK: - IAP methods
    
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case SKPaymentTransactionState.Restored: fallthrough
            case SKPaymentTransactionState.Purchased:
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                unlockManager()
            case SKPaymentTransactionState.Failed:
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                mvc?.purchaseButton.enabled = true
                mvc?.restoreButton.enabled = true
                mvc?.purchaseIndicator.stopAnimating()
                
                presentPurchaseFailureAlert()
            default: break
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
        if queue.transactions.count == 0 {
            presentRestoreFailureAlert()
        }
        
        for transaction in queue.transactions {
            let pID = transaction.payment.productIdentifier
            
            if pID == productID {
                unlockManager()
            }
        }
    }
    
    func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
        presentRestoreFailureAlert()
    }

    func presentPurchaseFailureAlert() {
        mvc?.restoreButton.setTitle("Restore", forState: UIControlState.Normal)
        mvc?.restoreButton.enabled = true
        mvc?.purchaseButton.enabled = true
        mvc?.purchaseIndicator.stopAnimating()
        
        let failAlert = UIAlertController(title: "Purchase Failed", message: "Please try again later.", preferredStyle: UIAlertControllerStyle.Alert)
        failAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        mvc?.presentViewController(failAlert, animated: true, completion: nil)
    }
    
    func presentRestoreFailureAlert() {
        let failAlert = UIAlertController(title: "Failed to Restore Purchases", message: "Please try again later. If the problem persists, you may not have purchased the product. To do so, use the purchase button above.", preferredStyle: UIAlertControllerStyle.Alert)
        failAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        mvc?.presentViewController(failAlert, animated: true, completion: nil)
    }
    
    func unlockManager() {
        defaults.setBool(true, forKey: "managerUnlocked")
        defaults.synchronize()
        productLock = false
        continueToAdd()
    }
    
    func getLockStatus() -> Bool {
        if medication.count >= trialLimit {
            if productLock == true {
                return true
            }
        }
        
        return false
    }
    
    func continueToAdd() {
        dismissViewControllerAnimated(true) { () -> Void in
            self.performSegueWithIdentifier("addMedication", sender: self)
        }
    }
    
    
    // MARK: - Navigation methods
    
    @IBAction func addMedication(sender: UIBarButtonItem) {
        if getLockStatus() == false {
            performSegueWithIdentifier("addMedication", sender: self)
        } else {
            performSegueWithIdentifier("upgrade", sender: self)
        }
    }
    
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
        
        if segue.identifier == "upgrade" {
            if let vc = segue.destinationViewController.childViewControllers[0] as? UpgradeVC {
                mvc = vc
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
            
            // If medication has specified alert time, schedule first dose
            if addMed.intervalUnit == Intervals.Daily && addMed.intervalAlarm != nil {
                addMed.scheduleNextNotification()
            }
        }
    }
    
    @IBAction func medicationUnwindCancel(unwindSegue: UIStoryboardSegue) {
        moc.rollback()
        self.tableView.reloadData()
    }
    
    @IBAction func historyUnwindAdd(unwindSegue: UIStoryboardSegue) {
        if let selectedIndex = tableView.indexPathForSelectedRow {
            let svc = unwindSegue.sourceViewController as! AddDoseTVC
            let med = medication[selectedIndex.row]
            
            do {
                try med.takeDose(moc, date: svc.date)
                appDelegate.saveContext()
                self.tableView.reloadData()
            } catch {
                dismissViewControllerAnimated(true, completion: { () -> Void in
                    self.presentDoseAlert(med, date: svc.date)
                })
            }
        }
    }
    
    @IBAction func historyUnwindCancel(unwindSegue: UIStoryboardSegue) {}
    
    
    // MARK: - Local notifications
    
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
                do {
                    try med.takeDose(moc, date: NSDate())
                    appDelegate.saveContext()
                    self.tableView.reloadData()
                } catch {}
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
    
    
    // MARK: - Helper methods
    
    func printNotifications() {
        let notifications = UIApplication.sharedApplication().scheduledLocalNotifications!
        
        if notifications.count != 0 {
            print("Scheduled notifications:")
        
            for (index, notification) in notifications.enumerate() {
                if let id = notification.userInfo?["id"] {
                    if let med = Medicine.getMedicine(arr: medication, id: id as! String) {
                        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
                        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
                        print("\t\(index): [\(id)] \t \(med.name!): \(dateFormatter.stringFromDate(notification.fireDate!))")
                    }
                }
            }
            
            print("\n")
        } else {
            print("No scheduled notifications.\n")
        }
    }
    
    func presentDoseAlert(med: Medicine, date: NSDate) {
        let doseAlert = UIAlertController(title: "Repeat Dose?", message: "You have logged a dose for \(med.name!) within the passed 5 minutes, do you wish to log another dose?", preferredStyle: UIAlertControllerStyle.Alert)
        
        doseAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))

        doseAlert.addAction(UIAlertAction(title: "Add Dose", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
            med.addDose(moc, date: date)
        }))
        
        self.presentViewController(doseAlert, animated: true, completion: nil)
    }
    
}
