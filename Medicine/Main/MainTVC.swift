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
    
    let defaults = NSUserDefaults(suiteName: "group.com.ebarer.Medicine")!
    let productID = "com.ebarer.Medicine.Unlock"
    var mvc: UpgradeVC?
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext!
    var launchedShortcutItem: [NSObject: AnyObject]?
    
    let cal = NSCalendar.currentCalendar()
    let dateFormatter = NSDateFormatter()
    
    
    // MARK: - IAP variables

    let trialLimit = 2
    var productLock = true
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set mananged object context
        moc = appDelegate.managedObjectContext
        
        // Add observeres for notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "internalNotification:", name: "medNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "takeMedicationNotification:", name: "takeDoseNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "snoozeReminderNotification:", name: "snoozeReminderNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTableAndNotifications", name: UIApplicationWillEnterForegroundNotification, object: nil)
        defaults.addObserver(self, forKeyPath: "sortOrder", options: NSKeyValueObservingOptions.New, context: nil)
        
        // Register for 3D touch if available
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .Available {
                registerForPreviewingWithDelegate(self, sourceView: view)
            }
        }
        
        // Display tutorial on first launch
        if !defaults.boolForKey("firstLaunch") {
            defaults.setBool(true, forKey: "firstLaunch")
            appDelegate.window!.rootViewController?.performSegueWithIdentifier("tutorial", sender: self)
        }
        
        // Setup IAP
        if defaults.boolForKey("managerUnlocked") {
            productLock = false
        } else {
            productLock = true
        }
        
        // Modify VC tint and Navigation Item
        self.view.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        self.clearsSelectionOnViewWillAppear = false
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        // Add logo to navigation bar
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "Logo-Nav"))
        
        // Remove tableView gap
        tableView.tableHeaderView = UIView(frame: CGRectMake(0.0, 0.0, tableView.bounds.size.width, 0.01))
        
        // Cancel all existing notifications
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
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
                
                // If selected, sort by next dosage
                if defaults.integerForKey("sortOrder") == 1 {
                    medication.sortInPlace(sortByNextDose)
                }

                setDynamicShortcuts()
            }
        } catch {
            print("Could not fetch medication.")
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(true, animated: true)
        
        // Handle application shortcuts
        if #available(iOS 9.0, *) {
            if let shortcutItem = launchedShortcutItem?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
                if let action = shortcutItem.userInfo?["action"] {
                    switch(String(action)) {
                    case "addMedication":
                        performSegueWithIdentifier("addMedication", sender: self)
                    case "takeDose":
                        performSegueWithIdentifier("addDose", sender: self)
                    default: break
                    }
                }
                
                launchedShortcutItem = nil
            }
        }
        
        // If no medications, display empty message
        displayEmptyView()
        
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func reloadMedication() {
        let request = NSFetchRequest(entityName:"Medicine")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        
        do {
            let fetchedResults = try moc.executeFetchRequest(request) as? [Medicine]
            
            if let results = fetchedResults {
                medication = results
                
                // If selected, sort by next dosage
                if defaults.integerForKey("sortOrder") == 1 {
                    medication.sortInPlace(sortByNextDose)
                }
                
                self.tableView.reloadData()
            }
        } catch {
            print("Could not fetch medication.")
        }
    }

    
    // Create banner
    
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
        return updateHeader()
    }
    
    func updateHeader() -> UIView? {
        
        // Setup summary labels
        var string = NSMutableAttributedString(string: "No more doses today")
        string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))
        headerCounterLabel.attributedText = string
        headerDescriptionLabel.text = nil
        headerMedLabel.text = nil
        var todayData = [String: AnyObject]()
        
        // Warn of overdue doses
        let overdueItems = medication.filter({$0.isOverdue().flag}).count
        if overdueItems > 0  {
            var text = "Overdue dose"
            
            // Pluralize string if multiple overdue doses
            if overdueItems > 1 {
                text += "s"
            }
            
            string = NSMutableAttributedString(string: text)
            string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))
            headerCounterLabel.attributedText = string
        }
            
        // Show next scheduled dose
        else if let nextDose = UIApplication.sharedApplication().scheduledLocalNotifications?.first {
            if cal.isDateInToday(nextDose.fireDate!) {
                if let id = nextDose.userInfo?["id"] {
                    if let med = Medicine.getMedicine(arr: medication, id: id as! String) {
                        headerDescriptionLabel.text = "Next Dose"
                        
                        // let dif = cal.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: NSDate(), toDate: nextDose.fireDate!, options: [])
                        dateFormatter.dateFormat = "h:mma"
                        
                        string = NSMutableAttributedString(string: dateFormatter.stringFromDate(nextDose.fireDate!))
                        let len = string.length
                        string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(70.0, weight: UIFontWeightUltraLight), range: NSMakeRange(0, len-2))
                        string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0), range: NSMakeRange(len-2, 2))
                        headerCounterLabel.attributedText = string
                        
                        let dose = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
                        headerMedLabel.text = "\(dose) of \(med.name!)"

                        todayData["date"] = nextDose.fireDate!
                    }
                }
            }
        }
            
        // Prompt to take first dose
        else if medication.count > 0 {
            string = NSMutableAttributedString(string: "Take first dose")
            string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))
            headerCounterLabel.attributedText = string
        }
        
        todayData["descriptionString"] = headerDescriptionLabel.text
        todayData["dateString"] = headerCounterLabel.text
        todayData["medString"] = headerMedLabel.text

        defaults.setObject((todayData as NSDictionary), forKey: "todayData")
        defaults.synchronize()

        return summaryHeader
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
        cell.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        
        // Set medication name
        cell.textLabel?.text = med.name
        cell.textLabel?.textColor = UIColor.blackColor()
        
        // If reminders aren't enabled for medication, set subtitle to last dose taken
        if med.reminderEnabled == false {
            if let date = med.lastDose?.next {
                var subtitle:NSMutableAttributedString!
                
                if date.compare(NSDate()) == .OrderedDescending {
                    subtitle = NSMutableAttributedString(string: "Earliest next dose: \(cellDateString(date))")
                    subtitle.addAttribute(NSForegroundColorAttributeName, value: UIColor.lightGrayColor(), range: NSMakeRange(0, 20))
                } else {
                    subtitle = NSMutableAttributedString(string: "Last dose: \(cellDateString(date))")
                    subtitle.addAttribute(NSForegroundColorAttributeName, value: UIColor.lightGrayColor(), range: NSMakeRange(0, 10))
                }
                
                cell.detailTextLabel?.attributedText = subtitle
                return cell
            }
        }
        
        // If medication is overdue, set subtitle to next dosage date and tint red
        if med.isOverdue().flag {
            cell.textLabel?.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
            var subtitle = NSMutableAttributedString(string: "Overdue")
            
            if let date = med.isOverdue().lastDose {
                subtitle = NSMutableAttributedString(string: "Overdue: \(cellDateString(date))")
            }
            
            subtitle.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0), range: NSMakeRange(0, subtitle.length))
            subtitle.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFontOfSize(15.0), range: NSMakeRange(0, 7))
            cell.detailTextLabel?.attributedText = subtitle
            return cell
        }
        
        // Set subtitle to next dosage date
        if let date = med.nextDose {
            let subtitle = NSMutableAttributedString(string: "Next dose: \(cellDateString(date))")
            subtitle.addAttribute(NSForegroundColorAttributeName, value: UIColor.lightGrayColor(), range: NSMakeRange(0, 10))
            cell.detailTextLabel?.attributedText = subtitle
            return cell
        }
        
        // If no doses taken, or other conditions met, instruct user on how to take dose
        else  {
            cell.detailTextLabel?.attributedText = NSAttributedString(string: "Tap to take first dose", attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()])
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        medication[fromIndexPath.row].sortOrder = Int16(toIndexPath.row)
        medication[toIndexPath.row].sortOrder = Int16(fromIndexPath.row)
        medication.sortInPlace({ $0.sortOrder < $1.sortOrder })
        appDelegate.saveContext()
        
        // Set sort order to "manually"
        defaults.setInteger(0, forKey: "sortOrder")
        defaults.synchronize()
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
                if med.reminderEnabled {
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
            }
            
            let alert = UIAlertController(title: med.name, message: dateString, preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            alert.addAction(UIAlertAction(title: "Take Dose", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
                self.performSegueWithIdentifier("addDose", sender: med)
            }))
            
            // If next dosage is set, allow user to clear notification
            if (med.nextDose != nil) {
                alert.addAction(UIAlertAction(title: "Undo Last Dose", style: UIAlertActionStyle.Destructive, handler: {(action) -> Void in
                    if (med.untakeLastDose(self.moc)) {
                        self.appDelegate.saveContext()
                        
                        // If selected, sort by next dosage
                        if self.defaults.integerForKey("sortOrder") == 1 {
                            self.medication.sortInPlace(self.sortByNextDose)
                        }
                        
                        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                        self.updateHeader()
                        self.setDynamicShortcuts()
                    } else {
                        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                    }
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: {(action) -> Void in
                if let name = med.name {
                    self.presentDeleteAlert(name, indexPath: indexPath)
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {(action) -> Void in
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }))
            
            // Set popover for iPad
            if let view = tableView.cellForRowAtIndexPath(indexPath)?.textLabel {
                alert.popoverPresentationController?.sourceView = view
                alert.popoverPresentationController?.sourceRect = view.bounds
                alert.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Left
            }
            
            alert.view.tintColor = UIColor.grayColor()
            presentViewController(alert, animated: true, completion: nil)
        } else {
            performSegueWithIdentifier("editMedication", sender: indexPath.row)
        }
    }
    
    
    // MARK: - Delete methods
    
    func presentDeleteAlert(name: String, indexPath: NSIndexPath) {
        let deleteAlert = UIAlertController(title: "Delete \(name)?", message: "This will permanently delete \(name) and all of its history.", preferredStyle: UIAlertControllerStyle.Alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {(action) -> Void in
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: {(action) -> Void in
            self.deleteMed(indexPath)
        }))
        
        deleteAlert.view.tintColor = UIColor.grayColor()
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
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        
        updateHeader()
        setDynamicShortcuts()
    }
    
    func displayEmptyView() {
        if medication.count == 0 {
            navigationItem.leftBarButtonItem?.enabled = false
            
            // Create empty message
            if let emptyView = UINib(nibName: "MainEmptyView", bundle: nil).instantiateWithOwner(self, options: nil)[0] as? UIView {
                // Display message
                tableView.backgroundView = emptyView
                tableView.separatorStyle = UITableViewCellSeparatorStyle.None
            }
            
            tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        } else {
            navigationItem.leftBarButtonItem?.enabled = true
            tableView.backgroundView = nil
            tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            tableView.reloadData()
        }
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
            queue.finishTransaction(transaction)
            
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
        
        failAlert.view.tintColor = UIColor.grayColor()
        mvc?.presentViewController(failAlert, animated: true, completion: nil)
    }
    
    func presentRestoreFailureAlert() {
        mvc?.restoreButton.setTitle("Restore", forState: UIControlState.Normal)
        mvc?.restoreButton.enabled = true
        mvc?.purchaseButton.enabled = true
        mvc?.purchaseIndicator.stopAnimating()
        
        let failAlert = UIAlertController(title: "Restore Failed", message: "Please try again later. If the problem persists, use the purchase button above.", preferredStyle: UIAlertControllerStyle.Alert)
        failAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        failAlert.view.tintColor = UIColor.grayColor()
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
            let vc = segue.destinationViewController as! UINavigationController
            let addVC = vc.topViewController as! AddMedicationTVC
            addVC.title = "New Medication"
        }
        
        if segue.identifier == "editMedication" {
            let vc = segue.destinationViewController as! UINavigationController
            let addVC = vc.topViewController as! AddMedicationTVC
            addVC.title = "Edit Medication"
            addVC.med = medication[sender as! Int]
            addVC.editMode = true
        }
        
        if segue.identifier == "viewMedicationDetails" {
            let vc = segue.destinationViewController as! MedicineDetailsTVC
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
        
        if segue.identifier == "addDose" {
            if let vc = segue.destinationViewController.childViewControllers[0] as? AddDoseTVC {
                if let med = sender as? Medicine {
                    vc.med = med
                }
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
                tableView.insertRowsAtIndexPaths([newIndex], withRowAnimation: .None)
            }
            
            // If selected, sort by next dosage
            if defaults.integerForKey("sortOrder") == 1 {
                medication.sortInPlace(sortByNextDose)
            }
            
            // Update last dose properties
            do {
                addMed.lastDose?.dosage = addMed.dosage
                addMed.lastDose?.dosageUnitInt = addMed.dosageUnitInt
                addMed.lastDose?.next = try addMed.calculateNextDose(addMed.lastDose?.date)
            } catch {
                print("Unable to update last dose")
            }
            
            // Reschedule next notification
            addMed.scheduleNextNotification()
            
            self.tableView.reloadData()
            
            setDynamicShortcuts()
            setEditing(false, animated: true)
        }
    }
    
    @IBAction func medicationUnwindCancel(unwindSegue: UIStoryboardSegue) {
        moc.rollback()
        setEditing(false, animated: true)
        self.tableView.reloadData()
    }
    
    @IBAction func historyUnwindAdd(unwindSegue: UIStoryboardSegue) {
        let svc = unwindSegue.sourceViewController as! AddDoseTVC
        
        do {
            try svc.med?.takeDose(moc, date: svc.date)
            appDelegate.saveContext()
            
            // If selected, sort by next dosage
            if defaults.integerForKey("sortOrder") == 1 {
                medication.sortInPlace(sortByNextDose)
            }
            
            // Reload table
            if let index = self.tableView.indexPathForSelectedRow {
                updateHeader()
                self.tableView.reloadRowsAtIndexPaths([index], withRowAnimation: .Automatic)
            } else {
                self.tableView.reloadData()
            }
            
            setDynamicShortcuts()
        } catch {
            dismissViewControllerAnimated(true, completion: { () -> Void in
                if let med = svc.med {
                    self.presentDoseAlert(med, date: svc.date)
                }
            })
        }
    }
    
    @IBAction func unwindCancel(unwindSegue: UIStoryboardSegue) {
        if unwindSegue.sourceViewController.restorationIdentifier == "welcomeScreen" {
            reloadMedication()
        }
    }
    
    
    // MARK: - Observers
    
    func internalNotification(notification: NSNotification) {
        if let id = notification.userInfo!["id"] as? String {
            let medQuery = Medicine.getMedicine(arr: medication, id: id)
            if let med = medQuery {
                if let name = med.name {
                    let message = String(format:"Time to take %g %@ of %@", med.dosage, med.dosageUnit.units(med.dosage), name)
                    
                    let alert = UIAlertController(title: "Take \(name)", message: message, preferredStyle: .Alert)
                    
                    alert.addAction(UIAlertAction(title: "Take Dose", style:  UIAlertActionStyle.Destructive, handler: {(action) -> Void in
                        self.takeMedicationNotification(notification)
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Snooze", style: UIAlertActionStyle.Cancel, handler: {(action) -> Void in
                        self.snoozeReminderNotification(notification)
                    }))

                    alert.view.tintColor = UIColor.grayColor()
                    appDelegate.window!.rootViewController?.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func takeMedicationNotification(notification: NSNotification) {
        if let id = notification.userInfo!["id"] as? String {
            if let med = Medicine.getMedicine(arr: medication, id: id) {
                do {
                    try med.takeDose(moc, date: NSDate())
                    appDelegate.saveContext()
                    
                    // If selected, sort by next dosage
                    if defaults.integerForKey("sortOrder") == 1 {
                        medication.sortInPlace(sortByNextDose)
                    }
                    
                    // Reload table
                    self.tableView.reloadData()
                } catch {
                    dismissViewControllerAnimated(true, completion: { () -> Void in
                        self.presentDoseAlert(med, date: NSDate())
                    })
                }
            }
        } else {
            print("-E-: Cannot take next dose, no MedicineID specified")
        }
    }
    
    func snoozeReminderNotification(notification: NSNotification) {
        if let info = notification.userInfo {
            if let id = info["id"] as? String {
                let medQuery = Medicine.getMedicine(arr: medication, id: id)
                if let med = medQuery {
                    med.snoozeNotification()
                    appDelegate.saveContext()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        switch(defaults.integerForKey("sortOrder")) {
        case 0: // Manually
            medication.sortInPlace(sortByManual)
        case 1: // Next dosage
            medication.sortInPlace(sortByNextDose)
        default: break
        }
    }
    
    
    // MARK: - Sort methods
    
    func sortByNextDose(medA: Medicine, medB: Medicine) -> Bool {
        // Unscheduled medications should be at the bottom
        if medA.reminderEnabled == false {
            return false
        }
        
        if medB.reminderEnabled == false {
            return true
        }
        
        guard let next1 = medA.nextDose else {
            return false
        }
        
        guard let next2 = medB.nextDose else {
            return true
        }
        
        return next1.compare(next2) == .OrderedAscending
    }
    
    func sortByManual(medA: Medicine, medB: Medicine) -> Bool {
        return medA.sortOrder < medB.sortOrder
    }
    
    
    // MARK: - Helper methods
    
    func cellDateString(date: NSDate?) -> String {
        guard let date = date else { return "" }
        
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
        
        return dateString
    }
    
    func presentDoseAlert(med: Medicine, date: NSDate) {
        let doseAlert = UIAlertController(title: "Repeat Dose?", message: "You have logged a dose for \(med.name!) within the passed 5 minutes, do you wish to log another dose?", preferredStyle: UIAlertControllerStyle.Alert)
        
        doseAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))

        doseAlert.addAction(UIAlertAction(title: "Add Dose", style: UIAlertActionStyle.Destructive, handler: {(action) -> Void in
            med.addDose(self.moc, date: date)
            self.appDelegate.saveContext()
            
            // If selected, sort by next dosage
            if self.defaults.integerForKey("sortOrder") == 1 {
                self.medication.sortInPlace(self.sortByNextDose)
            }
            
            self.tableView.reloadData()
            
            self.setDynamicShortcuts()
        }))
        
        doseAlert.view.tintColor = UIColor.grayColor()
        self.presentViewController(doseAlert, animated: true, completion: nil)
    }
    
    func setDynamicShortcuts() {
        if #available(iOS 9.0, *) {
            let overdueItems = medication.filter({$0.isOverdue().flag})
            if overdueItems.count > 0  {
                var text = "Overdue Dose"
                var subtitle: String? = nil
                var userInfo = [String:String]()
                
                // Pluralize string if multiple overdue doses
                if overdueItems.count > 1 {
                    text += "s"
                }
                // Otherwise set subtitle to overdue med
                else {
                    let med = overdueItems.first!
                    subtitle = med.name!
                    userInfo["action"] = "takeDose"
                    userInfo["medID"] = med.medicineID
                }
                
                let shortcutItem = UIApplicationShortcutItem(type: "com.ebarer.Medicine.overdue",
                    localizedTitle: text, localizedSubtitle: subtitle,
                    icon: UIApplicationShortcutIcon(templateImageName: "OverdueGlyph"),
                    userInfo: userInfo)
                
                UIApplication.sharedApplication().shortcutItems = [shortcutItem]
                return
            } else if let nextDose = UIApplication.sharedApplication().scheduledLocalNotifications?.first {
                if let id = nextDose.userInfo?["id"] {
                    guard let med = Medicine.getMedicine(arr: medication, id: id as! String) else { return }
                    let dose = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
                    let date = nextDose.fireDate
                    let subtitle = "\(cellDateString(date)): \(dose) of \(med.name!)"
                    
                    let shortcutItem = UIApplicationShortcutItem(type: "com.ebarer.Medicine.takeDose",
                        localizedTitle: "Take Next Dose", localizedSubtitle: subtitle,
                        icon: UIApplicationShortcutIcon(templateImageName: "NextDoseGlyph"),
                        userInfo: ["action":"takeDose", "medID":med.medicineID])
                    
                    UIApplication.sharedApplication().shortcutItems = [shortcutItem]
                    return
                }
            }
            
            UIApplication.sharedApplication().shortcutItems = []
        }
    }
    
}
