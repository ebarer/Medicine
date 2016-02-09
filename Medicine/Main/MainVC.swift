//
//  MainVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-12-20.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData
import StoreKit
import CoreSpotlight
import MobileCoreServices

class MainVC: UIViewController, UITableViewDataSource, UITableViewDelegate, SKPaymentTransactionObserver {

    // MARK: - Outlets
    @IBOutlet var addMedicationButton: UIBarButtonItem!
    @IBOutlet var summaryHeader: UIView!
    @IBOutlet var headerDescriptionLabel: UILabel!
    @IBOutlet var headerCounterLabel: UILabel!
    @IBOutlet var headerMedLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: - Helper variables
    let defaults = NSUserDefaults(suiteName: "group.com.ebarer.Medicine")!
    var launchedShortcutItem: [NSObject: AnyObject]?
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext
    
    let cal = NSCalendar.currentCalendar()
    let dateFormatter = NSDateFormatter()
    
    var selectedMed: Medicine?
    
    
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
        
        // Add observers for notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshMainVC:", name: "refreshMain", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "medicationDeleted", name: "medicationDeleted", object: nil)
        
        // Register for 3D touch if available
        if traitCollection.forceTouchCapability == .Available {
            registerForPreviewingWithDelegate(self, sourceView: view)
        }
        
        // Setup IAP
        if defaults.boolForKey("managerUnlocked") {
            productLock = false
        } else {
            productLock = true
        }
        
        // Modify VC tint and Navigation Item
        self.view.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        
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
        
        updateHeader()
        
        // Deselect selection
        if let collapsed = self.splitViewController?.collapsed where collapsed == true {
            selectMed()
            
            if let selected = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRowAtIndexPath(selected, animated: true)
            }
        }
        
        // Handle homescreen shortcuts (selected by user)
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

        // Update spotlight index values
        (self.tabBarController as! MainTBC).indexMedication()
        
        setDynamicShortcuts()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Update values
    func refreshMainVC(notification: NSNotification? = nil) {
        
        if let tbc = self.tabBarController as? MainTBC {
            tbc.loadMedication()
        }

        updateHeader()
        refreshTable()
        
        let reload = notification?.userInfo?["reload"] as? Bool
        if reload == nil || reload != false {
            tableView.reloadData()
        }
        
        if let collapsed = self.splitViewController?.collapsed where collapsed == false {
            selectMed()
        }

        displayEmptyView()
    }
    
    func displayEmptyView() {
        if medication.count == 0 {
            // Display edit button
            self.navigationItem.rightBarButtonItems?.removeObject(self.editButtonItem())

            // Display empty message
            if self.view.viewWithTag(1001) == nil {     // Prevent duplicate empty views being added
                if let emptyView = UINib(nibName: "MainEmptyView", bundle: nil).instantiateWithOwner(self, options: nil)[0] as? UIView {
                    emptyView.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
                    emptyView.tag = 1001
                    emptyView.alpha = 0.0
                    self.view.addSubview(emptyView)
                    
                    UIView.animateWithDuration(0.5,
                        animations: { () -> Void in
                            self.summaryHeader.alpha = 0.0
                            self.tableView.alpha = 0.0
                            emptyView.alpha = 1.0
                        }, completion: { (val) -> Void in
                            self.summaryHeader.hidden = true
                            self.tableView.hidden = true
                    })
                }
            }
        } else {
            // Display edit button
            if let buttons = self.navigationItem.rightBarButtonItems {
                if buttons.contains(self.editButtonItem()) == false {
                    self.navigationItem.rightBarButtonItems?.append(self.editButtonItem())
                }
            }
            
            // Remove empty message
            if let emptyView = self.view.viewWithTag(1001) {
                emptyView.alpha = 0.0
                emptyView.removeFromSuperview()
            }
            
            summaryHeader.hidden = false
            self.summaryHeader.alpha = 1.0
            
            tableView.hidden = false
            self.tableView.alpha = 1.0
        }
    }
    
    func updateHeader() {
        // Initialize main string
        var string = NSMutableAttributedString(string: "No more doses today")
        string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))
        
        // Setup today widget data
        var todayData = [String: AnyObject]()
        todayData["date"] = nil
        
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
                        
                        dateFormatter.dateFormat = "h:mm a"
                        let date = dateFormatter.stringFromDate(nextDose.fireDate!)
                        string = NSMutableAttributedString(string: date)
                        string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(70.0, weight: UIFontWeightUltraLight), range: NSMakeRange(0, string.length))
                        
                        // Accomodate 24h times
                        let range = (date.containsString("AM")) ? date.rangeOfString("AM") : date.rangeOfString("PM")
                        if let range = range {
                            let pos = date.startIndex.distanceTo(range.startIndex)
                            string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0), range: NSMakeRange(pos-1, 3))
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
    }
    
    
    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return medication.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
        
        // Set subtitle and attributes
        cell.hideGlyph(false)
        cell.subtitleGlyph.image = UIImage(named: "NextDoseIcon")
        cell.subtitle.textColor = UIColor.blackColor()
        cell.hideButton(false)
        let dose = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
        
        // If no doses taken, and medication is hourly
        if med.doseHistory?.count == 0 && med.intervalUnit == .Hourly {
            cell.hideButton(true)
            cell.subtitleGlyph.image = UIImage(named: "AddDoseIcon")
            cell.subtitle.textColor = UIColor.lightGrayColor()
            cell.subtitle.text = "Tap to take first dose"
        }
            
        // If reminders aren't enabled for medication
        else if med.reminderEnabled == false {
            cell.subtitleGlyph.image = UIImage(named: "LastDoseIcon")
            cell.subtitle.textColor = UIColor.lightGrayColor()
            
            if let date = med.lastDose?.date {
                cell.subtitle.text = "\(dose), \(Medicine.dateString(date))"
            } else {
                cell.subtitle.text = "No doses logged"
            }
        } else {
            // If medication is overdue, set subtitle to next dosage date and tint red
            if med.isOverdue().flag {
                cell.title.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
                cell.subtitleGlyph.image = UIImage(named: "OverdueIcon")
                
                if let date = med.isOverdue().overdueDose {
                    cell.subtitle.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
                    cell.subtitle.text = "\(dose), \(Medicine.dateString(date))"
                }
            }
                
            // If notification scheduled, set date to next scheduled fire date
            else if let date = med.scheduledNotifications?.first?.fireDate {
                cell.subtitle.text = "\(dose), \(Medicine.dateString(date))"
            }
                
            // Set subtitle to next dosage date
            else if let date = med.nextDose {
                cell.subtitle.text = "\(dose), \(Medicine.dateString(date))"
            }
                
            // If no other conditions met, instruct user on how to take dose
            else {
                cell.hideButton(true)
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
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        if fromIndexPath != toIndexPath {
            medication[fromIndexPath.row].sortOrder = Int16(toIndexPath.row)
            medication[toIndexPath.row].sortOrder = Int16(fromIndexPath.row)
            medication.sortInPlace({ $0.sortOrder < $1.sortOrder })
            
            appDelegate.saveContext()
            
            // Set sort order to "manually"
            defaults.setInteger(0, forKey: "sortOrder")
            defaults.synchronize()
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    // Empty implementation required for backwards compatibility (iOS 8.x)
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {}
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let editAction = UITableViewRowAction(style: .Default, title: "Edit") { (action, indexPath) -> Void in
            self.performSegueWithIdentifier("editMedication", sender: medication[indexPath.row])
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
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        tableView.setEditing(editing, animated: animated)
        
        for i in 0..<tableView.numberOfRowsInSection(0) {
            let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) as! MedicineCell
            cell.addButton.hidden = editing
        }
        
        // Select med "selected" in Detail view
        if let collapsed = self.splitViewController?.collapsed where collapsed == false {
            if editing == false {
                selectMed()
            }
        }
    }
    
    func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
        if let collapsed = self.splitViewController?.collapsed where collapsed == false {
            selectMed()
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedMed = medication[indexPath.row]
        
        if tableView.editing == true {
            performSegueWithIdentifier("editMedication", sender: medication[indexPath.row])
        }
    }
    
    @IBAction func selectAddButton(sender: UIButton) {
        let cell = (sender.superview?.superview as! MedicineCell)
        if let indexPath = self.tableView.indexPathForCell(cell) {
            presentActionMenu(indexPath)
        }
    }
    
    func selectMed() {
        if let med = selectedMed {
            if let row = medication.indexOf(med) {
                tableView.selectRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0), animated: false, scrollPosition: .None)
            }
        }
    }
    
    func presentActionMenu(index: NSIndexPath) {
        if tableView.editing == false {
            let med = medication[index.row]
            var dateString:String? = nil
            
            if let date = med.lastDose?.date {
                dateString = "Last Dose: \(Medicine.dateString(date, today: true))"
            }
            
            let alert = UIAlertController(title: med.name, message: dateString, preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            alert.addAction(UIAlertAction(title: "Take Dose", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
                self.performSegueWithIdentifier("addDose", sender: med)
                self.tableView.deselectRowAtIndexPath(index, animated: false)
            }))
            
            if med.isOverdue().flag {
                alert.addAction(UIAlertAction(title: "Snooze Dose", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
                    med.snoozeNotification()
                    self.tableView.deselectRowAtIndexPath(index, animated: false)
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Skip Dose", style: UIAlertActionStyle.Destructive, handler: {(action) -> Void in
                let entity = NSEntityDescription.entityForName("Dose", inManagedObjectContext: self.moc)
                let dose = Dose(entity: entity!, insertIntoManagedObjectContext: self.moc)
                
                dose.medicine = med
                dose.dosage = -1
                dose.dosageUnitInt = med.dosageUnitInt
                dose.date = NSDate()
                
                med.addDose(dose)
                
                self.appDelegate.saveContext()
                
                // If selected, sort by next dosage
                if self.defaults.integerForKey("sortOrder") == SortOrder.NextDosage.rawValue {
                    medication.sortInPlace(Medicine.sortByNextDose)
                    self.tableView.reloadData()
                } else {
                    self.tableView.reloadRowsAtIndexPaths([index], withRowAnimation: UITableViewRowAnimation.None)
                }
                
                NSNotificationCenter.defaultCenter().postNotificationName("refreshView", object: nil)
                NSNotificationCenter.defaultCenter().postNotificationName("refreshMain", object: nil)
                
                // Update spotlight index values
                (self.tabBarController as! MainTBC).indexMedication()
                
                // Update shortcuts
                self.setDynamicShortcuts()
            }))
            
            // If last dose is set, allow user to undo last dose
            if (med.lastDose != nil) {
                alert.addAction(UIAlertAction(title: "Undo Last Dose", style: UIAlertActionStyle.Destructive, handler: {(action) -> Void in
                    if (med.untakeLastDose(self.moc)) {
                        // If selected, sort by next dosage
                        if self.defaults.integerForKey("sortOrder") == SortOrder.NextDosage.rawValue {
                            medication.sortInPlace(Medicine.sortByNextDose)
                            self.tableView.reloadData()
                        } else {
                            self.tableView.reloadRowsAtIndexPaths([index], withRowAnimation: UITableViewRowAnimation.None)
                        }
                        
                        self.updateHeader()
                        
                        // Update spotlight index values
                        (self.tabBarController as! MainTBC).indexMedication()
                        
                        // Update shortcuts
                        self.setDynamicShortcuts()
                    } else {
                        self.tableView.deselectRowAtIndexPath(index, animated: false)
                    }
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Refill Prescription", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
                self.performSegueWithIdentifier("refillPrescription", sender: med)
                self.tableView.deselectRowAtIndexPath(index, animated: false)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {(action) -> Void in
                self.tableView.deselectRowAtIndexPath(index, animated: false)
            }))
            
            // Set popover for iPad
            if let cell = tableView.cellForRowAtIndexPath(index) as? MedicineCell {
                alert.popoverPresentationController?.sourceView = cell.title
                let rect = CGRectMake(cell.title.bounds.origin.x, cell.title.bounds.origin.y, cell.title.bounds.width + 5, cell.title.bounds.height)
                alert.popoverPresentationController?.sourceRect = rect
                alert.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Left
            }
            
            alert.view.layoutIfNeeded()
            alert.view.tintColor = UIColor.grayColor()
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func takeDose(sender: UILongPressGestureRecognizer) {
        let point = sender.locationInView(self.tableView)
        if let indexPath = self.tableView?.indexPathForRowAtPoint(point) {
            let med = medication[indexPath.row]
            
            if (sender.state == .Began) {
                self.performSegueWithIdentifier("addDose", sender: med)
                self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
            }
        }
    }
    
    
    // MARK: - Actions
    func presentDeleteAlert(name: String, indexPath: NSIndexPath) {
        let deleteAlert = UIAlertController(title: "Delete \(name)?", message: "This will permanently delete \(name) and all of its history.", preferredStyle: UIAlertControllerStyle.Alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {(action) -> Void in
            self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
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
        med.cancelNotifications()
        
        // Remove med from details
        if let svc = self.splitViewController where svc.viewControllers.count > 1 {
            if let detailVC = (svc.viewControllers[1] as? UINavigationController)?.topViewController as? MedicineDetailsTVC {
                if let selectedMed = detailVC.med {
                    if med == selectedMed {
                        detailVC.med = nil
                    }
                }
            }
        }
        
        // Remove medication from array
        medication.removeAtIndex(indexPath.row)
        
        // Remove medication from persistent store
        moc.deleteObject(med)
        appDelegate.saveContext()
        
        // Update spotlight index
        CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers([med.medicineID], completionHandler: nil)
        
        // Update shortcuts
        setDynamicShortcuts()
        
        if medication.count == 0 {
            displayEmptyView()
        } else {
            // Remove medication from array
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("refreshView", object: nil)
        NSNotificationCenter.defaultCenter().postNotificationName("refreshMain", object: nil, userInfo: ["reload":false])
    }
    
    func medicationDeleted() {
        // Dismiss any modal views
        if let _ = self.navigationController?.presentedViewController {
            dismissViewControllerAnimated(true, completion: nil)
        }
        
        if let svc = self.splitViewController {
            if svc.collapsed {
                (svc.viewControllers[0] as! UINavigationController).popToRootViewControllerAnimated(true)
            }
        }
    }
    
    
    // MARK: - Navigation methods
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if tableView.editing == true {
            switch identifier {
            case "addMedication":
                return true
            case "editMedication":
                return true
            case "upgrade":
                return true
            default:
                return false
            }
        }
        
        if identifier == "viewMedicationDetails" {
            if let index = self.tableView.indexPathForCell(sender as! UITableViewCell) {
                let med = medication[index.row]
                if med.doseHistory?.count == 0 && med.intervalUnit == .Hourly {
                    presentActionMenu(index)
                    return false
                }
            }
        }
        
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "viewMedicationDetails" {
            if let nvc = segue.destinationViewController as? UINavigationController {
                if let vc = nvc.topViewController as? MedicineDetailsTVC {
                    if let index = self.tableView.indexPathForCell(sender as! UITableViewCell) {
                        vc.med = medication[index.row]
                        if let modeButton = self.splitViewController?.displayModeButtonItem() {
                            vc.navigationItem.leftBarButtonItem = modeButton
                            vc.navigationItem.leftItemsSupplementBackButton = true
                        
                            // Hide master on selection in split view
                            UIApplication.sharedApplication().sendAction(modeButton.action, to: modeButton.target, from: nil, forEvent: nil)
                        }
                    }
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
        
        if segue.identifier == "editMedication" {
            if let vc = segue.destinationViewController.childViewControllers[0] as? AddMedicationTVC {
                if let med = sender as? Medicine {
                    vc.med = med
                    vc.editMode = true
                }
            }
        }
        
        if segue.identifier == "upgrade" {
            if let vc = segue.destinationViewController.childViewControllers[0] as? UpgradeVC {
                mvc = vc
            }
        }
    }
    
    @IBAction func addMedication(sender: UIBarButtonItem) {
        if appLocked() == false {
            performSegueWithIdentifier("addMedication", sender: self)
        } else {
            performSegueWithIdentifier("upgrade", sender: self)
        }
    }
    
    @IBAction func unwindCancel(unwindSegue: UIStoryboardSegue) {
        if let _ = unwindSegue.sourceViewController as? WelcomeVC {
            refreshMainVC()
        }
    }
    
    
    // MARK: - IAP methods
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case SKPaymentTransactionState.Restored:
                queue.finishTransaction(transaction)
                unlockManager()
            case SKPaymentTransactionState.Purchased:
                queue.finishTransaction(transaction)
                unlockManager()
            case SKPaymentTransactionState.Failed:
                queue.finishTransaction(transaction)
                
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
