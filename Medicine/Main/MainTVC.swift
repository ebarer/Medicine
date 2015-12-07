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
import CoreSpotlight
import MobileCoreServices

class MainTVC: UITableViewController, SKPaymentTransactionObserver {

    // MARK: - Outlets
    
    @IBOutlet var addMedicationButton: UIBarButtonItem!
    @IBOutlet var summaryHeader: UIView!
    @IBOutlet var headerDescriptionLabel: UILabel!
    @IBOutlet var headerCounterLabel: UILabel!
    @IBOutlet var headerMedLabel: UILabel!
    

    // MARK: - Helper variables
    
    let defaults = NSUserDefaults(suiteName: "group.com.ebarer.Medicine")!
    var launchedShortcutItem: [NSObject: AnyObject]?
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext
    
    let cal = NSCalendar.currentCalendar()
    let dateFormatter = NSDateFormatter()
    
    
    // MARK: - IAP variables
    
    let productID = "com.ebarer.Medicine.Unlock"
    let trialLimit = 2
    var productLock = true
    var mvc: UpgradeVC?

    
    // MARK: - Initialization
    
    required init?(coder aDecoder: NSCoder) {
        // Setup context
        moc = appDelegate.managedObjectContext
        
        super.init(coder: aDecoder)
    }
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If selected, sort by next dosage
        if defaults.integerForKey("sortOrder") == SortOrder.NextDosage.rawValue {
            medication.sortInPlace(Medicine.sortByNextDose)
        }
        
        // Add observeres for notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateHeader", name: "refreshWidget", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshMedication", name: "refreshMedication", object: nil)
        
        // Register for 3D touch if available
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .Available {
                registerForPreviewingWithDelegate(self, sourceView: view)
            }
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
        
        // Setup refresh timer
        let _ = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(300), target: self, selector: Selector("refreshTable"), userInfo: nil, repeats: true)

        
        // Display tutorial on first launch
        let dictionary = NSBundle.mainBundle().infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        if defaults.stringForKey("version") != version {
            defaults.setValue(version, forKey: "version")
            self.performSegueWithIdentifier("tutorial", sender: self)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(true, animated: true)
        
        // Handle homescreen shortcuts (selected by user)
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
        
        if #available(iOS 9.0, *) {
            // Update spotlight index values
            for med in medication {
                if let attributes = med.attributeSet {
                    let item = CSSearchableItem(uniqueIdentifier: med.medicineID, domainIdentifier: nil, attributeSet: attributes)
                    CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([item], completionHandler: nil)
                }
            }
            
            setDynamicShortcuts()
        }
        
        updateTableView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
        return updateHeader()
    }
    
    
    // MARK: - Update values
    
    func refreshMedication() {
        NSNotificationCenter.defaultCenter().postNotificationName("rescheduleNotifications", object: nil, userInfo: nil)
        
        updateHeader()
        
        // Update spotlight index
        if #available(iOS 9.0, *) {
            for med in medication {
                if let attributes = med.attributeSet {
                    let item = CSSearchableItem(uniqueIdentifier: med.medicineID, domainIdentifier: nil, attributeSet: attributes)
                    CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([item], completionHandler: nil)
                }
            }
        }
        
        // Update shortcuts
        self.setDynamicShortcuts()
        
        // If selected, sort by next dosage
        if defaults.integerForKey("sortOrder") == SortOrder.NextDosage.rawValue {
            medication.sortInPlace(Medicine.sortByNextDose)
        }
        
        // Dismiss editing mode
        setEditing(false, animated: true)
        
        tableView.reloadData()
    }
    
    func updateHeader() -> UIView? {
        // Initialize main string
        var string = NSMutableAttributedString(string: "No more doses today")
        string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))
        
        // Setup today widget data
        var todayData = [String: AnyObject]()
        todayData["date"] = nil
        
        // Remove animation
        summaryHeader.layer.removeAllAnimations()
        
        // Setup summary labels
        headerCounterLabel.attributedText = string
        headerDescriptionLabel.text = nil
        headerMedLabel.text = nil
        
        
        // Warn of overdue doses
        let overdueItems = medication.filter({$0.isOverdue().flag})
        if overdueItems.count > 0  {
            var text = "Overdue dose"
            
            // Pluralize string if multiple overdue doses
            if overdueItems.count > 1 {
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
                        
                        dateFormatter.dateFormat = "h:mma"
                        let date = dateFormatter.stringFromDate(nextDose.fireDate!)
                        string = NSMutableAttributedString(string: date)
                        string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(70.0, weight: UIFontWeightUltraLight), range: NSMakeRange(0, string.length))

                        // Accomodate 24h times
                        let range = (date.containsString("AM")) ? date.rangeOfString("AM") : date.rangeOfString("PM")
                        if let range = range {
                            let pos = date.startIndex.distanceTo(range.startIndex)
                            string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0), range: NSMakeRange(pos, 2))
                        }
                        
                        headerCounterLabel.attributedText = string
                        
                        let dose = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
                        headerMedLabel.text = "\(dose) of \(med.name!)"
                    }
                }
            }
            
            todayData["date"] = nextDose.fireDate!
        }
            
            // Prompt to take first dose
        else if medication.count > 0 {
            if medication.first?.lastDose == nil {
                string = NSMutableAttributedString(string: "Take first dose")
                string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))
                headerCounterLabel.attributedText = string
            }
        }
        
        // Set today widget information
        todayData["descriptionString"] = headerDescriptionLabel.text
        todayData["dateString"] = headerCounterLabel.text
        todayData["medString"] = headerMedLabel.text
        
        defaults.setObject((todayData as NSDictionary), forKey: "todayData")
        defaults.synchronize()
        
        return summaryHeader
    }
    
    func updateTableView() {
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
            
            // Reschedule notifications
            NSNotificationCenter.defaultCenter().postNotificationName("rescheduleNotifications", object: nil, userInfo: nil)
            
            // If selected, sort by next dosage
            if defaults.integerForKey("sortOrder") == SortOrder.NextDosage.rawValue {
                medication.sortInPlace(Medicine.sortByNextDose)
            }
            
            // Dismiss editing mode
            setEditing(false, animated: true)
            
            tableView.reloadData()
        }
    }
    
    func refreshTable() {
        // Reschedule notifications
        NSNotificationCenter.defaultCenter().postNotificationName("rescheduleNotifications", object: nil, userInfo: nil)
        
        // If selected, sort by next dosage
        if defaults.integerForKey("sortOrder") == SortOrder.NextDosage.rawValue {
            medication.sortInPlace(Medicine.sortByNextDose)
        }
        
        // Dismiss editing mode
        setEditing(false, animated: true)
        
        tableView.reloadData()
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
        let med = medication[indexPath.row]
        
        // Configure cell
        let cell = tableView.dequeueReusableCellWithIdentifier("medicineCell", forIndexPath: indexPath) as! MedicineCell
        
        // Set medication name
        cell.title.text = med.name
        cell.title.textColor = UIColor.blackColor()
        
        // Set adherence score
        if let score = med.adherenceScore() {
            cell.adherenceScore.score = score
            cell.adherenceScoreLabel.text = "\(score)"
        } else {
            cell.adherenceScoreLabel.text = "—"
        }
        
        // Set subtitle
        cell.hideGlyph(false)
        cell.subtitleGlyph.image = UIImage(named: "NextDoseIcon")
        cell.subtitle.textColor = UIColor.blackColor()
        
        // If no doses taken
        if med.doseHistory?.count == 0 {
            cell.subtitleGlyph.image = UIImage(named: "AddDoseIcon")
            cell.subtitle.textColor = UIColor.lightGrayColor()
            cell.subtitle.text = "Tap to take first dose"
        }
        
        // If reminders aren't enabled for medication
        else if med.reminderEnabled == false {
            if let date = med.lastDose?.next {
                if date.compare(NSDate()) == .OrderedDescending {
                    cell.hideGlyph(true)
                    cell.subtitle.textColor = UIColor.lightGrayColor()
                    cell.subtitle.text = "Unscheduled, \(Medicine.dateString(date))"
                } else {
                    cell.subtitleGlyph.image = UIImage(named: "AddDoseIcon")
                    cell.subtitle.textColor = UIColor.lightGrayColor()
                    cell.subtitle.text = "Tap to take next dose"
                }
            }
        }
        
        else {
            // If medication is overdue, set subtitle to next dosage date and tint red
            if med.isOverdue().flag {
                cell.title.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
                
                var subtitle = "Overdue"
                if let date = med.isOverdue().overdueDose {
                    subtitle = Medicine.dateString(date)
                }
                
                cell.subtitleGlyph.image = UIImage(named: "OverdueIcon")
                cell.subtitle.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
                cell.subtitle.text = subtitle
            }
                
            // If notification scheduled, set date to next scheduled fire date
            else if let date = med.scheduledNotifications?.first?.fireDate {
                cell.subtitle.text = Medicine.dateString(date)
            }
                
            // Set subtitle to next dosage date
            else if let date = med.nextDose {
                cell.subtitle.text = Medicine.dateString(date)
            }
                
            // If no other conditions met, instruct user on how to take dose
            else {
                cell.subtitleGlyph.image = UIImage(named: "AddDoseIcon")
                cell.subtitle.textColor = UIColor.lightGrayColor()
                cell.subtitle.text = "Tap to take first dose"
            }
        }
        
        // Add long press gesture recognizer
        cell.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "takeDose:"))
        
        return cell
    }

    
    // MARK: - Table actions
    
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
            if let name = medication[indexPath.row].name {
                self.presentDeleteAlert(name, indexPath: indexPath)
            }
        }
        
        return [deleteAction, editAction]
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
                    //dateString?.appendContentsOf(Medicine.dateString(date))
                    
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
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }))
            
            // If last dose is set, allow user to clear notification
            if (med.lastDose != nil) {
                alert.addAction(UIAlertAction(title: "Undo Last Dose", style: UIAlertActionStyle.Destructive, handler: {(action) -> Void in
                    if (med.untakeLastDose(self.moc)) {
                        // If selected, sort by next dosage
                        if self.defaults.integerForKey("sortOrder") == SortOrder.NextDosage.rawValue {
                            medication.sortInPlace(Medicine.sortByNextDose)
                            self.tableView.reloadData()
                        } else {
                            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                        }
                        
                        self.updateHeader()
                        
                        // Update spotlight index
                        if #available(iOS 9.0, *) {
                            if let attributes = med.attributeSet {
                                let item = CSSearchableItem(uniqueIdentifier: med.medicineID, domainIdentifier: nil, attributeSet: attributes)
                                CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([item], completionHandler: nil)
                            }
                        }
                        
                        // Update shortcuts
                        self.setDynamicShortcuts()
                    } else {
                        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                    }
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Refill Prescription", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
                self.performSegueWithIdentifier("refillPrescription", sender: med)
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }))
            
            alert.addAction(UIAlertAction(title: "View Details", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
                let cell = self.tableView.cellForRowAtIndexPath(indexPath)
                self.performSegueWithIdentifier("viewMedicationDetails", sender: cell)
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
    
    func takeDose(sender: UILongPressGestureRecognizer) {
        let point = sender.locationInView(self.tableView)
        if let indexPath = self.tableView?.indexPathForRowAtPoint(point) {
            let med = medication[indexPath.row]
            
            if (sender.state == .Began) {
                self.performSegueWithIdentifier("addDose", sender: med)
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
    }
    
    
    // MARK: - Actions
    
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
        let med = medication[indexPath.row]
        
        // Cancel all notifications for medication
        med.cancelNotification()
        
        // Remove medication from array
        medication.removeAtIndex(indexPath.row)
        
        // Remove medication from persistent store
        moc.deleteObject(med)
        appDelegate.saveContext()
        
        // Update spotlight index
        if #available(iOS 9.0, *) {
            CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers([med.medicineID], completionHandler: nil)
        }
        
        // Update shortcuts
        setDynamicShortcuts()
        
        if medication.count == 0 {
            updateTableView()
        } else {
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        
        updateHeader()
    }
    
    
    // MARK: - Navigation methods
    
    @IBAction func addMedication(sender: UIBarButtonItem) {
        if appLocked() == false {
            performSegueWithIdentifier("addMedication", sender: self)
        } else {
            performSegueWithIdentifier("upgrade", sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editMedication" {
            if let vc = segue.destinationViewController.childViewControllers[0] as? AddMedicationTVC {
                vc.med = medication[sender as! Int]
                vc.editMode = true
            }
        }
        
        if segue.identifier == "viewMedicationDetails" {
            if let vc = segue.destinationViewController as? MedicineDetailsTVC {
                if let index = self.tableView.indexPathForCell(sender as! UITableViewCell) {
                    vc.med = medication[index.row]
                }
            }
        }
        
        if segue.identifier == "addDose" {
            if let vc = segue.destinationViewController.childViewControllers[0] as? AddDoseTVC {
                if let med = sender as? Medicine {
                    vc.med = med
                }
            }
        }
        
        if segue.identifier == "refillPrescription" {
            if let vc = segue.destinationViewController.childViewControllers[0] as? AddRefillTVC {
                if let med = sender as? Medicine {
                    vc.med = med
                }
            }
        }
        
        if segue.identifier == "upgrade" {
            if let vc = segue.destinationViewController.childViewControllers[0] as? UpgradeVC {
                mvc = vc
            }
        }
    }
    
    @IBAction func unwindCancel(unwindSegue: UIStoryboardSegue) {
        if let _ = unwindSegue.sourceViewController as? WelcomeVC {
            refreshMedication()
        }
    }

    
    // MARK: - IAP methods
    
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case SKPaymentTransactionState.Restored:
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                unlockManager()
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
        for transaction in queue.transactions {
            queue.finishTransaction(transaction)
        }
        
        presentRestoreFailureAlert()
    }
    
    func presentPurchaseFailureAlert() {
        mvc?.restoreButton.setTitle("Restore Purchase", forState: UIControlState.Normal)
        mvc?.restoreButton.enabled = true
        mvc?.purchaseButton.enabled = true
        mvc?.purchaseIndicator.stopAnimating()
        
        let failAlert = UIAlertController(title: "Purchase Failed", message: "Please try again later.", preferredStyle: UIAlertControllerStyle.Alert)
        failAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        
        failAlert.view.tintColor = UIColor.grayColor()
        mvc?.presentViewController(failAlert, animated: true, completion: nil)
    }
    
    func presentRestoreFailureAlert() {
        mvc?.restoreButton.setTitle("Restore Purchase", forState: UIControlState.Normal)
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
    
    func appLocked() -> Bool {
        // If debug device, disable medication limit
        if defaults.boolForKey("debug") == true {
            return false
        }
        
        // If limit exceeded and product locked, return true
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
    
    
    // MARK: - Helper methods
    
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
                    let subtitle = "\(Medicine.dateString(date)): \(dose) of \(med.name!)"
                    
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
