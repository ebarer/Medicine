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
import UserNotifications

class MainVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets
    @IBOutlet var addMedicationButton: UIBarButtonItem!
    @IBOutlet var summaryHeader: UIView!
    @IBOutlet var headerDescriptionLabel: UILabel!
    @IBOutlet var headerCounterLabel: UILabel!
    @IBOutlet var headerMedLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Helper variables
    let cdStack = (UIApplication.shared.delegate as! AppDelegate).stack
    let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine")!
    
    var tbc: MainTBC? {
        return self.tabBarController as? MainTBC
    }
    
    var launchedShortcutItem: [AnyHashable: Any]?
    
    let cal = Calendar.current
    let dateFormatter = DateFormatter()
    
    var medication = [Medicine]()
    var selectedMed: Medicine?
    
    // MARK: - IAP variables
    let productID = "com.ebarer.Medicine.Unlock"
    let trialLimit = 2
    var productLock = true
    var mvc: UpgradeVC?
    
    var longPressGesture: UILongPressGestureRecognizer?
    
    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add observers for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(refreshMainVC(_:)), name: NSNotification.Name(rawValue: "refreshMain"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(medicationDeleted), name: NSNotification.Name(rawValue: "medicationDeleted"), object: nil)
        
        // Register for 3D touch if available
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }
        
        // Setup IAP
        if defaults.bool(forKey: "managerUnlocked") {
            productLock = false
        } else {
            productLock = true
        }
        
        // Modify VC tint and Navigation Item
        self.view.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        
        // Add logo to navigation bar
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "Logo-Nav"))
        
        // Remove tableView gap
        //tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.bounds.size.width, height: 0.01))
        tableView.separatorStyle = .none
        
        // Setup refresh timer
        let _ = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(refreshTable), userInfo: nil, repeats: true)
        
        // Display tutorial on first launch
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        if defaults.string(forKey: "version") != version {
            defaults.setValue(version, forKey: "version")
            self.performSegue(withIdentifier: "tutorial", sender: self)
        }
    }
    
    func loadMedication() {
        // Create fetch request, sorted by task time
        let fetchRequest: NSFetchRequest<Medicine> = Medicine.fetchRequest()

        if defaults.integer(forKey: "sortOrder") == SortOrder.nextDosage.rawValue {
            // Sort by next dose
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "reminderEnabled", ascending: false),
                NSSortDescriptor(key: "dateNextDose", ascending: true)
            ]
        } else {
            // Sort by manually defined sort order
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        }

        if let results = try? cdStack.context.fetch(fetchRequest) {
            medication = results
//            logMedication()
        }
    }
    
    func logMedication() {
        for med in medication {
            if let date = med.dateNextDose {
                print("\(med.sortOrder): \(med.name ?? "") [\(med.medicineID)] -> \(date)")
            } else {
                print("\(med.sortOrder): \(med.name ?? "") [\(med.medicineID)] -> No next dose")
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(true, animated: true)
        
        refreshTable()
        updateHeader()
        displayEmptyView()
        
        // Deselect selection
        if let collapsed = self.splitViewController?.isCollapsed, collapsed == true {
            selectMed()
            
            if let selectedIndex = self.tableView.indexPathForSelectedRow {
                if let cell = self.tableView.cellForRow(at: selectedIndex) as? MedicineCell {
                    cell.cellFrame?.layer.backgroundColor = UIColor(white: 0.9, alpha: 1).cgColor

                    self.transitionCoordinator?.animate(alongsideTransition: { (context) in
                        cell.cellFrame?.layer.backgroundColor = UIColor.white.cgColor
                    }, completion: { (context) in
                        if !context.isCancelled {
                            self.tableView.deselectRow(at: selectedIndex, animated: animated)
                            self.selectedMed = nil
                        }
                    })
                }
            }
        }
        
        // Handle home screen shortcuts (selected by user)
        if let shortcutItem = launchedShortcutItem?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            if let action = shortcutItem.userInfo?["action"] {
                switch(String(describing: action)) {
                case "addMedication":
                    performSegue(withIdentifier: "addMedication", sender: self)
                case "takeDose":
                    performSegue(withIdentifier: "addDose", sender: self)
                default: break
                }
            }
            
            launchedShortcutItem = nil
        }

        // Update spotlight index values and home screen shortcuts
        tbc?.indexMedication()
        tbc?.setDynamicShortcuts()
        
        self.view.layoutIfNeeded()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Update values
    @objc func refreshMainVC(_ notification: Notification? = nil) {
        refreshTable()
        updateHeader()
        
        let reload = notification?.userInfo?["reload"] as? Bool
        if reload == nil || reload != false {
            tableView.reloadData()
        }
        
        if let collapsed = self.splitViewController?.isCollapsed, collapsed == false {
            selectMed()
        }

        displayEmptyView()
    }
    
    func displayEmptyView() {
        if medication.count == 0 {
            // Display edit button
            self.navigationItem.rightBarButtonItems?.removeObject(self.editButtonItem)

            // Display empty message
            if self.view.viewWithTag(1001) == nil {     // Prevent duplicate empty views being added
                if let emptyView = UINib(nibName: "MainEmptyView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView {
                    emptyView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
                    emptyView.tag = 1001
                    emptyView.alpha = 0.0
                    self.view.addSubview(emptyView)
                    
                    UIView.animate(withDuration: 0.5,
                        animations: { () -> Void in
                            self.summaryHeader.alpha = 0.0
                            self.tableView.alpha = 0.0
                            emptyView.alpha = 1.0
                        }, completion: { (val) -> Void in
                            self.summaryHeader.isHidden = true
                            self.tableView.isHidden = true
                    })
                }
            }
        } else {
            // Display edit button
            if let buttons = self.navigationItem.rightBarButtonItems {
                if buttons.contains(self.editButtonItem) == false {
                    self.navigationItem.rightBarButtonItems?.append(self.editButtonItem)
                }
            }
            
            // Remove empty message
            if let emptyView = self.view.viewWithTag(1001) {
                emptyView.alpha = 0.0
                emptyView.removeFromSuperview()
            }
            
            summaryHeader.isHidden = false
            self.summaryHeader.alpha = 1.0
            
            tableView.isHidden = false
            self.tableView.alpha = 1.0
        }
    }
    
    func updateHeader() {
        // Initialize main string
        var string = NSMutableAttributedString(string: "No more doses today")
        string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 32.0, weight: UIFont.Weight.light), range: NSMakeRange(0, string.length))
        
        // Setup today widget data
        var todayData = [String: AnyObject]()
        todayData["date"] = nil
        
        // Setup summary labels
        headerCounterLabel.attributedText = string
        headerDescriptionLabel.text = nil
        headerMedLabel.text = nil
        
        let nextMed = medication.sorted(by: Medicine.sortByNextDose).filter({ $0.reminderEnabled == true }).first
        if let date = nextMed?.nextDose {
            // If dose is in the past, warn of overdue doses
            if date.compare(Date()) == .orderedAscending {
                string = NSMutableAttributedString(string: "Overdue")
                string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 32.0, weight: UIFont.Weight.light), range: NSMakeRange(0, string.length))
                string.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(red: 1, green: 0, blue: 51/255, alpha: 1), range: NSMakeRange(0, string.length))
                
                headerCounterLabel.attributedText = string
            }
            // Show next scheduled dose
            else {
                headerDescriptionLabel.text = "Next Dose"

                dateFormatter.dateFormat = "h:mm a"
                let dateString = dateFormatter.string(from: date)
                string = NSMutableAttributedString(string: dateString)
                string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 70.0, weight: UIFont.Weight.thin), range: NSMakeRange(0, string.length))

                // Accomodate 24h times
                let range = (dateString.contains("AM")) ? dateString.range(of: "AM") : dateString.range(of: "PM")
                if let range = range {
                    let pos = dateString.characters.distance(from: dateString.startIndex, to: range.lowerBound)
                    string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 24.0), range: NSMakeRange(pos-1, 3))
                    string.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(white: 0, alpha: 0.3), range: NSMakeRange(pos-1, 3))
                }

                headerCounterLabel.attributedText = string

                let dose = String(format:"%g %@", nextMed!.dosage, nextMed!.dosageUnit.units(nextMed!.dosage))
                headerMedLabel.text = "\(dose) of \(nextMed!.name!)"
            }
        }
        // Prompt to take first dose
        else if medication.count > 0 {
            if medication.first?.lastDose == nil {
                string = NSMutableAttributedString(string: "Take first dose")
                string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 32.0, weight: UIFont.Weight.light), range: NSMakeRange(0, string.length))
                headerCounterLabel.attributedText = string
            }
        }
        
        // Set today widget information
        todayData["descriptionString"] = headerDescriptionLabel.text as AnyObject?
        todayData["dateString"] = headerCounterLabel.text as AnyObject?
        todayData["medString"] = headerMedLabel.text as AnyObject?
        
        defaults.set((todayData as NSDictionary), forKey: "todayData")
        defaults.synchronize()
    }
    
    @objc func refreshTable() {
        if !self.tableView.isEditing {
            loadMedication()
            self.tableView.reloadSections([0], with: .none)
        }
    }
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return medication.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let med = medication[indexPath.row]
        
        // Configure cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "medicineCell", for: indexPath) as! MedicineCell
        
        // Set medication name
        cell.title.text = med.name
        cell.title.textColor = UIColor.black
        
        // Set subtitle and attributes
        cell.subtitleGlyph.image = UIImage(named: "NextDoseIcon")
        cell.subtitle.textColor = UIColor.black
        cell.hideButton(false)
        let dose = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
        
        // If no doses taken, and medication is hourly
        if med.doseHistory?.count == 0 && med.intervalUnit == .hourly {
            cell.hideButton(true, animated: false)
            cell.subtitleGlyph.image = UIImage(named: "AddDoseIcon")
            cell.subtitle.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
            cell.subtitle.text = "Tap to take first dose"
        }
            
        // If reminders aren't enabled for medication
        else if med.reminderEnabled == false {
            cell.subtitleGlyph.image = UIImage(named: "NextDoseIcon")
            cell.subtitle.textColor = UIColor(white: 0.5, alpha: 1)
            
            if let date = med.nextDose {
                // If next date is in the past, instruct user they can take next dose
                if date.compare(Date()) == .orderedAscending {
                    cell.subtitle.text = "Take next dose as needed"
                } else {
                    cell.subtitle.text = "\(dose), \(Medicine.dateString(date))"
                }
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
                
            // Set subtitle to next dosage date
            else if let date = med.nextDose {
                cell.subtitle.text = "\(dose), \(Medicine.dateString(date))"
            }
                
            // If no other conditions met, instruct user on how to take dose
            else {
                cell.hideButton(true)
                cell.subtitleGlyph.image = UIImage(named: "AddDoseIcon")
                cell.subtitle.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
                cell.subtitle.text = "Tap to take first dose"
            }
        }
        
        // Add long press gesture recognizer
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(takeDose(_:)))
        cell.longPressGesture = longPressGesture
        
        return cell
    }
    
    
    // MARK: - Table actions
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        if fromIndexPath != toIndexPath {
            // Update medication array
            let med = medication[fromIndexPath.row]
            medication.remove(at: fromIndexPath.row)
            medication.insert(med, at: toIndexPath.row)
            
            // Update sort order
            for (index, med) in medication.enumerated() {
                med.sortOrder = Int16(index)
            }

            cdStack.save()

            // Set sort order to "manually"
            defaults.set(0, forKey: "sortOrder")
            defaults.synchronize()
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let takeAction = UIContextualAction(style: .normal, title: "Take\nDose") { (action, view, success: (Bool) -> Void) in
            self.performSegue(withIdentifier: "addDose", sender: self.medication[indexPath.row])
            success(true)
        }

        takeAction.image = UIImage(named: "TakeDoseAction")
        takeAction.backgroundColor = UIColor.darkGray

        return UISwipeActionsConfiguration(actions: [takeAction])
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let editAction = UITableViewRowAction(style: .normal, title: "Edit") { (action, indexPath) -> Void in
            self.performSegue(withIdentifier: "editMedication", sender: self.medication[indexPath.row])
        }
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) -> Void in
            if let name = self.medication[indexPath.row].name {
                self.presentDeleteAlert(name, indexPath: indexPath)
            }
        }
        
        return [deleteAction, editAction]
    }
    
    
    // MARK: - Table view delegate
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        tableView.setEditing(editing, animated: animated)
        
        // Select med "selected" in Detail view
        if let collapsed = self.splitViewController?.isCollapsed, collapsed == false {
            if editing == false {
                selectMed()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        if let collapsed = self.splitViewController?.isCollapsed, collapsed == false {
            selectMed()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedMed = medication[indexPath.row]
        
        if tableView.isEditing == true {
            performSegue(withIdentifier: "editMedication", sender: medication[indexPath.row])
        }
    }
    
    @IBAction func selectAddButton(_ sender: UIButton) {
        let pos = sender.convert(CGPoint(), to: tableView)
        if let indexPath = tableView.indexPathForRow(at: pos) {
            presentActionMenu(indexPath)
        }
    }
    
    func selectMed() {
        if let med = selectedMed {
            if let row = medication.index(of: med) {
                tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
            }
        }
    }
    
    func presentActionMenu(_ index: IndexPath) {
        if tableView.isEditing == false {
            let med = medication[index.row]
            var dateString:String? = nil
            
            if let date = med.lastDose?.date {
                dateString = "Last Dose: \(Medicine.dateString(date, today: true))"
            }
            
            let alert = UIAlertController(title: med.name, message: dateString, preferredStyle: UIAlertControllerStyle.actionSheet)
            
            alert.addAction(UIAlertAction(title: "Take Dose", style: UIAlertActionStyle.default, handler: {(action) -> Void in
                self.performSegue(withIdentifier: "addDose", sender: med)
                self.tableView.deselectRow(at: index, animated: false)
            }))
            
            if med.isOverdue().flag {
                alert.addAction(UIAlertAction(title: "Snooze Dose", style: UIAlertActionStyle.default, handler: {(action) -> Void in
                    med.snoozeNotification()
                    self.tableView.deselectRow(at: index, animated: false)
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Skip Dose", style: UIAlertActionStyle.destructive, handler: {(action) -> Void in
                let dose = Dose(insertInto: self.cdStack.context)
                dose.date = Date()
                dose.dosage = -1
                dose.dosageUnit = med.dosageUnit
                med.addDose(dose)
                
                self.cdStack.save()
                
                // If selected, sort by next dosage
                if self.defaults.integer(forKey: "sortOrder") == SortOrder.nextDosage.rawValue {
                    self.medication.sort(by: Medicine.sortByNextDose)
                    self.tableView.reloadData()
                } else {
                    self.tableView.reloadRows(at: [index], with: UITableViewRowAnimation.none)
                }
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
                
                // Update spotlight index values and home screen shortcuts
                self.tbc?.indexMedication()
                self.tbc?.setDynamicShortcuts()
            }))
            
            // If last dose is set, allow user to undo last dose
            if (med.lastDose != nil) {
                alert.addAction(UIAlertAction(title: "Undo Last Dose", style: UIAlertActionStyle.destructive, handler: {(action) -> Void in
                    if (med.untakeLastDose(self.cdStack.context)) {
                        // If selected, sort by next dosage
                        if self.defaults.integer(forKey: "sortOrder") == SortOrder.nextDosage.rawValue {
                            self.loadMedication()
                            self.tableView.reloadSections([0], with: .automatic)
                        } else {
                            self.tableView.reloadRows(at: [index], with: UITableViewRowAnimation.none)
                        }
                        
                        self.updateHeader()
                        
                        // Update spotlight index values and home screen shortcuts
                        self.tbc?.indexMedication()
                        self.tbc?.setDynamicShortcuts()
                    } else {
                        self.tableView.deselectRow(at: index, animated: false)
                    }
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Refill Prescription", style: UIAlertActionStyle.default, handler: {(action) -> Void in
                self.performSegue(withIdentifier: "refillPrescription", sender: med)
                self.tableView.deselectRow(at: index, animated: false)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {(action) -> Void in
                self.tableView.deselectRow(at: index, animated: false)
            }))
            
            // Set popover for iPad
            if let cell = tableView.cellForRow(at: index) as? MedicineCell {
                alert.popoverPresentationController?.sourceView = cell.title
                let rect = CGRect(x: cell.title.bounds.origin.x, y: cell.title.bounds.origin.y, width: cell.title.bounds.width + 5, height: cell.title.bounds.height)
                alert.popoverPresentationController?.sourceRect = rect
                alert.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.left
            }
            
            alert.view.layoutIfNeeded()
            alert.view.tintColor = UIColor.gray
            present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func takeDose(_ sender: UILongPressGestureRecognizer) {
        let point = sender.location(in: self.tableView)
        if let indexPath = self.tableView?.indexPathForRow(at: point) {
            let med = medication[indexPath.row]
            
            if (sender.state == .began) {
                self.performSegue(withIdentifier: "addDose", sender: med)
                self.tableView.deselectRow(at: indexPath, animated: false)
            }
        }
    }
    
    
    // MARK: - Actions
    func presentDeleteAlert(_ name: String, indexPath: IndexPath) {
        let deleteAlert = UIAlertController(title: "Delete \(name)?", message: "This will permanently delete \(name) and all of its history.", preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {(action) -> Void in
            self.tableView.deselectRow(at: indexPath, animated: false)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: {(action) -> Void in
            self.deleteMed(indexPath)
        }))
        
        deleteAlert.view.tintColor = UIColor.gray
        self.present(deleteAlert, animated: true, completion: nil)
    }
    
    func deleteMed(_ indexPath: IndexPath) {
        let med = medication[indexPath.row]
        
        // Cancel all notifications for medication
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [med.refillNotificationIdentifier])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [med.doseNotificationIdentifier])
        
        // Remove med from details
        if let svc = self.splitViewController, svc.viewControllers.count > 1 {
            if let detailVC = (svc.viewControllers[1] as? UINavigationController)?.topViewController as? MedicineDetailsTVC {
                if let selectedMed = detailVC.med {
                    if med == selectedMed {
                        detailVC.med = nil
                    }
                }
            }
        }
        
        // Remove medication from array
        medication.remove(at: indexPath.row)
        
        // Remove medication from persistent store
        cdStack.context.delete(med)
        cdStack.save()
        
        // Update spotlight index values and home screen shortcuts
        tbc?.removeIndex(med: med)
        tbc?.setDynamicShortcuts()
        
        if medication.count == 0 {
            displayEmptyView()
        } else {
            // Remove medication from array
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil, userInfo: ["reload":false])
    }
    
    @objc func medicationDeleted() {
        // Dismiss any modal views
        if let _ = self.navigationController?.presentedViewController {
            dismiss(animated: true, completion: nil)
        }
        
        if let svc = self.splitViewController {
            if svc.isCollapsed {
                (svc.viewControllers[0] as! UINavigationController).popToRootViewController(animated: true)
            }
        }
    }
    
    
    // MARK: - Navigation methods
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if tableView.isEditing == true {
            switch identifier {
            case "addMedication":
                return true
            case "editMedication":
                return true
            case "upgrade":
                return true
            case "displaySettings":
                return true
            default:
                return false
            }
        }
        
        if identifier == "viewMedicationDetails" {
            if let index = self.tableView.indexPath(for: sender as! UITableViewCell) {
                let med = medication[index.row]
                if med.doseHistory?.count == 0 && med.intervalUnit == .hourly {
                    presentActionMenu(index)
                    return false
                }
            }
        }
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewMedicationDetails" {
            if let nvc = segue.destination as? UINavigationController {
                if let vc = nvc.topViewController as? MedicineDetailsTVC {
                    if let index = self.tableView.indexPath(for: sender as! UITableViewCell) {
                        vc.med = medication[index.row]
                        if let modeButton = self.splitViewController?.displayModeButtonItem {
                            vc.navigationItem.leftBarButtonItem = modeButton
                            vc.navigationItem.leftItemsSupplementBackButton = true
                        
                            // Hide master on selection in split view
                            UIApplication.shared.sendAction(modeButton.action!, to: modeButton.target, from: nil, for: nil)
                        }
                    }
                }
            }
        }
        
        if segue.identifier == "addDose" {
            if let vc = segue.destination.childViewControllers[0] as? AddDoseTVC {
                if let med = sender as? Medicine {
                    vc.med = med
                }
            }
        }
        
        if segue.identifier == "refillPrescription" {
            if let vc = segue.destination.childViewControllers[0] as? AddRefillTVC {
                if let med = sender as? Medicine {
                    vc.med = med
                }
            }
        }
        
        if segue.identifier == "editMedication" {
            if let vc = segue.destination.childViewControllers[0] as? AddMedicationTVC {
                if let med = sender as? Medicine {
                    vc.med = med
                    vc.editMode = true
                }
            }
        }
        
        if segue.identifier == "upgrade" {
            if let vc = segue.destination.childViewControllers[0] as? UpgradeVC {
                mvc = vc
            }
        }
    }
    
    @IBAction func addMedication(_ sender: UIBarButtonItem) {
        if appLocked() == false {
            performSegue(withIdentifier: "addMedication", sender: self)
        } else {
            performSegue(withIdentifier: "upgrade", sender: self)
        }
    }
}

// MARK: - IAP methods
extension MainVC: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case SKPaymentTransactionState.restored:
                queue.finishTransaction(transaction)
                unlockManager()
            case SKPaymentTransactionState.purchased:
                queue.finishTransaction(transaction)
                unlockManager()
            case SKPaymentTransactionState.failed:
                queue.finishTransaction(transaction)
                
                mvc?.purchaseButton.isEnabled = true
                mvc?.restoreButton.isEnabled = true
                mvc?.purchaseIndicator.stopAnimating()
                
                presentPurchaseFailureAlert()
            default: break
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
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
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        for transaction in queue.transactions {
            queue.finishTransaction(transaction)
        }
        
        presentRestoreFailureAlert()
    }
    
    func presentPurchaseFailureAlert() {
        mvc?.restoreButton.setTitle("Restore Purchase", for: UIControlState())
        mvc?.restoreButton.isEnabled = true
        mvc?.purchaseButton.isEnabled = true
        mvc?.purchaseIndicator.stopAnimating()
        
        let failAlert = UIAlertController(title: "Purchase Failed", message: "Please try again later.", preferredStyle: UIAlertControllerStyle.alert)
        failAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        failAlert.view.tintColor = UIColor.gray
        mvc?.present(failAlert, animated: true, completion: nil)
    }
    
    func presentRestoreFailureAlert() {
        mvc?.restoreButton.setTitle("Restore Purchase", for: UIControlState())
        mvc?.restoreButton.isEnabled = true
        mvc?.purchaseButton.isEnabled = true
        mvc?.purchaseIndicator.stopAnimating()
        
        let failAlert = UIAlertController(title: "Restore Failed", message: "Please try again later. If the problem persists, use the purchase button above.", preferredStyle: UIAlertControllerStyle.alert)
        failAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        failAlert.view.tintColor = UIColor.gray
        mvc?.present(failAlert, animated: true, completion: nil)
    }
    
    func unlockManager() {
        defaults.set(true, forKey: "managerUnlocked")
        defaults.synchronize()
        productLock = false
        continueToAdd()
    }
    
    func appLocked() -> Bool {
        // If debug device, disable medication limit
        if defaults.bool(forKey: "debug") == true {
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
        dismiss(animated: true) { () -> Void in
            self.performSegue(withIdentifier: "addMedication", sender: self)
        }
    }
}
