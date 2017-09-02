//
//  MedicineDetailsTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-12-05.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class MedicineDetailsTVC: UITableViewController, UITextFieldDelegate, UITextViewDelegate {
    
    weak var med:Medicine?
    
    // MARK: - Outlets
    @IBOutlet var nameCell: UITableViewCell!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var doseDetailsLabel: UILabel!
    @IBOutlet var doseCell: UITableViewCell!
    @IBOutlet var doseTitle: UILabel!
    @IBOutlet var doseLabel: UILabel!
    @IBOutlet var prescriptionLabel: UILabel!
    @IBOutlet var actionCell: UITableViewCell!
    @IBOutlet var takeDoseButton: UIButton!
    @IBOutlet var refillButton: UIButton!
    @IBOutlet var actionsButton: UIButton!
    @IBOutlet var notesField: UITextView!
    
    
    // MARK: - Helper variables
    let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine")!
    let cdStack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    var tbc: MainTBC? {
        return self.tabBarController as? MainTBC
    }
    
    let cal = Calendar.current
    let dateFormatter = DateFormatter()
    
    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.cellLayoutMarginsFollowReadableWidth = true
        
        // Setup edit button
        let editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editMedication))
        self.navigationItem.rightBarButtonItem = editButton
        
        // Add observeres for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(refreshDetails), name: NSNotification.Name(rawValue: "refreshView"), object: nil)
        
        // Register for 3D touch if available
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect selected row
        if let index = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: index, animated: animated)
        }
        
        if let tBC = self.tabBarController {
            tBC.setTabBarVisible(true, animated: false)
            self.navigationController?.setToolbarHidden(true, animated: false)
        }
        
        // Update actions
        takeDoseButton.layer.cornerRadius = 10.0
        refillButton.layer.cornerRadius = 10.0
        
        displayEmptyView()
        updateLabels()
        
        tableView.reloadSections(IndexSet(integer: Rows.name.index().section), with: .none)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func refreshDetails() {
        // Select first medication if none selected
        if med == nil {
            let fetchRequest: NSFetchRequest<Medicine> = Medicine.fetchRequest()
            
            if defaults.integer(forKey: "sortOrder") == SortOrder.nextDosage.rawValue {
                // Sort by next dose
                fetchRequest.sortDescriptors = [
                    NSSortDescriptor(key: "reminderEnabled", ascending: false),
                    NSSortDescriptor(key: "hasNextDose", ascending: false),
                    NSSortDescriptor(key: "dateNextDose", ascending: true),
                    NSSortDescriptor(key: "dateLastDose", ascending: false)
                ]
            } else {
                // Sort by manually defined sort order
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
            }
            
            if let medication = try? cdStack.context.fetch(fetchRequest) {
                self.med = medication.first
            }
        }
        
        displayEmptyView()
        updateLabels()
    }
    
    func displayEmptyView() {
        if med == nil {
            if self.view.viewWithTag(1001) == nil {     // Prevent duplicate empty views being added
                if let emptyView = UINib(nibName: "DetailEmptyView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView {
                    emptyView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
                    emptyView.tag = 1001
                    self.view.addSubview(emptyView)
                    self.tableView.isScrollEnabled = false
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                }
            }
        } else {
            self.view.viewWithTag(1001)?.removeFromSuperview()
            self.tableView.isScrollEnabled = true
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    func updateLabels() {
        if let med = med {
            nameLabel.textColor = UIColor.black
            nameLabel.text = med.name
            
            var detailsString = "\(med.dosage.removeTrailingZero()) \(med.dosageUnit.units(med.dosage))"
                detailsString += ", every \(med.intervalLabel())"
            
            doseDetailsLabel.text = detailsString
            
            var prescriptionString = ""
            if let count = med.refillHistory?.count, count > 0 {
                let count = med.prescriptionCount
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = NumberFormatter.Style.decimal
                
                if count.isZero {
                    prescriptionString = "None remaining"
                } else if let count = numberFormatter.string(from: NSNumber(value: count)) {
                    prescriptionString = "\(count) \(med.dosageUnit.units(med.prescriptionCount)) remaining"
                }
            } else {
                prescriptionString = "None"
            }
            
            prescriptionLabel.text = prescriptionString
            
            notesField.text = med.notes
            
            updateDose()
            
            // Correct inset
            tableView.reloadRows(at: [Rows.name.index()], with: .none)
        }
    }
    
    func updateDose() {
        if let med = med {
            // Set defaults
            nameCell.imageView?.image = nil
            nameLabel.textColor = UIColor.black
            
            doseTitle.textColor = UIColor.lightGray
            doseTitle.text = "Next Dose"
            
            doseLabel.textColor = UIColor.black
            doseLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.regular)
            
            // If no doses taken
            if med.doseHistory?.count == 0 && med.intervalUnit == .hourly {
                doseTitle.text = "No doses logged"
                doseLabel.text?.removeAll()
            }
            
            // If reminders aren't enabled for medication
            else if med.reminderEnabled == false {
                if let date = med.lastDose?.date {
                    doseTitle.text = "Last Dose"
                    doseLabel.text = Medicine.dateString(date)
                } else {
                    doseTitle.text = "No doses logged"
                    doseLabel.text?.removeAll()
                }
            } else {
                // If medication is overdue, set subtitle to next dosage date and tint red
                if med.isOverdue().flag {
                    nameCell.imageView?.image = UIImage(named: "OverdueGlyph")
                    nameCell.imageView?.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
                    nameLabel.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
                    
                    doseTitle.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
                    doseTitle.text = "Overdue"

                    if let date = med.isOverdue().overdueDose {
                        doseLabel.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
                        doseLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.medium)
                        doseLabel.text = Medicine.dateString(date)
                    }
                }
                    
                // Set subtitle to next dosage date
                else if let date = med.nextDose {
                    doseLabel.text = Medicine.dateString(date)
                }
                    
                // If no other conditions met, instruct user on how to take dose
                else {
                    doseTitle.text = "No doses logged"
                    doseLabel.text?.removeAll()
                }
            }
        }
    }
    
    // MARK: - Button events
    @IBAction func touchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2) {
            sender.layer.backgroundColor = sender.layer.backgroundColor?.copy(alpha: 0.5)
        }
    }
    
    @IBAction func touchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2) {
            sender.layer.backgroundColor = sender.layer.backgroundColor?.copy(alpha: 1.0)
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case Rows.name.index().section:
            return 15.0
        case Rows.notes.index().section:
            return ((med?.prescriptionCount ?? 0) > 0) ? 45.0 : 25.0
        default:
            return 1.0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == Rows.notes.index().section && med != nil {
            return "Notes"
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch Rows(index: indexPath) {
        case Rows.name:
            return 70.0
        case Rows.prescriptionCount:
            return ((med?.refillHistory?.count ?? 0) > 0) ? tableView.rowHeight : 0.0
        case Rows.actions:
            return 100.0
        case Rows.notes:
            let height = notesField.contentSize.height + 10
            return (height > 75.0) ? height : 75.0
        default:
            return 50.0
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.preservesSuperviewLayoutMargins = true
        
        switch Rows(index: indexPath) {
        case Rows.doseDetails:
            if med?.refillHistory?.count == 0 {
                cell.separatorInset = UIEdgeInsets.zero
            }
        case Rows.prescriptionCount:
            cell.separatorInset = UIEdgeInsets.zero
        case Rows.actions:
            cell.separatorInset = UIEdgeInsets.zero
        default: break
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if let med = med {
            if section == Rows.prescriptionCount.index().section && med.prescriptionCount > 0 {
                var status: String? = nil
                
                if med.prescriptionCount < med.dosage {
                    status = "You do not appear to have enough \(med.name!) remaining to take the next dose. "
                } else {                
                    if let days = med.refillDaysRemaining() {
                        if days <= 1 {
                            status = "You will need to refill after the next dose. "
                        } else {
                            status = "Based on current usage, your prescription should last approximately \(days) \(Intervals.daily.units(Float(days))). "
                        }
                    } else {
                        status = "Continue taking doses to receive a duration approximation for your prescription."
                    }
                }
                
                return status
            }
        }
        
        return nil
    }
    
    
    // MARK: - Table view delegates
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = Rows(index: indexPath)
        
        switch row {
        case Rows.name:
            performSegue(withIdentifier: "editMedication", sender: indexPath)
        case Rows.nextDose:
            performSegue(withIdentifier: "addDose", sender: nil)
        case Rows.prescriptionCount:
            performSegue(withIdentifier: "refillPrescription", sender: nil)
        case Rows.delete:
            presentDeleteAlert(indexPath)
        default: break
        }
    }
    
    
    // MARK: - Handle notes field
    func textViewDidChange(_ textView: UITextView) {
        med?.notes = textView.text
        cdStack.save()

        tableView.beginUpdates()
        tableView.endUpdates()
    }


    // MARK: - Actions
    @objc func editMedication() {
        performSegue(withIdentifier: "editMedication", sender: nil)
    }
    
    @IBAction func presentActionMenu(_ sender: UIButton) {
        guard let med = med else {
            return
        }
        
        var dateString: String? = nil
        if let date = med.lastDose?.date {
            dateString = "Last Dose: \(Medicine.dateString(date, today: true))"
        }
        
        let alert = UIAlertController(title: med.name, message: dateString, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        if med.isOverdue().flag {
            alert.addAction(UIAlertAction(title: "Snooze Dose", style: UIAlertActionStyle.default, handler: {(action) -> Void in
                med.snoozeNotification()
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Skip Dose", style: UIAlertActionStyle.destructive, handler: {(action) -> Void in
            let dose = Dose(insertInto: self.cdStack.context)
            dose.date = Date()
            dose.dosage = -1
            dose.dosageUnit = med.dosageUnit
            med.addDose(dose)
            
            self.cdStack.save()
            
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
                    // Update spotlight index values and home screen shortcuts
                    self.tbc?.indexMedication()
                    self.tbc?.setDynamicShortcuts()
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
                }
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel))
        
        // Set popover for iPad
        alert.popoverPresentationController?.sourceView = actionsButton
        alert.popoverPresentationController?.sourceRect = actionsButton.bounds.insetBy(dx: 0, dy: 14)
        alert.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
        
        alert.view.layoutIfNeeded()
        alert.view.tintColor = UIColor.gray
        present(alert, animated: true, completion: nil)
    }

    func presentDeleteAlert(_ indexPath: IndexPath) {
        if let med = med {
            if let name = med.name {
                let deleteAlert = UIAlertController(title: "Delete \(name)?", message: "This will permanently delete \(name) and all of its history.", preferredStyle: UIAlertControllerStyle.alert)
                
                deleteAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {(action) -> Void in
                    self.tableView.deselectRow(at: indexPath, animated: true)
                }))
                
                deleteAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: {(action) -> Void in
                    self.deleteMed()
                }))
                
                deleteAlert.view.tintColor = UIColor.gray
                self.present(deleteAlert, animated: true, completion: nil)
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func deleteMed() {
        if let med = med {
            // Cancel all notifications for medication
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [med.refillNotificationIdentifier])
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [med.doseNotificationIdentifier])
            
            // Remove medication from array
            self.med = nil
            
            // Remove medication from persistent store
            cdStack.context.delete(med)
            cdStack.save()

            // Send notifications
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "medicationDeleted"), object: nil)
        }
    }
    
    
    // MARK: - Peek actions
    override var previewActionItems : [UIPreviewActionItem] {
        return previewActions
    }

    lazy var previewActions: [UIPreviewActionItem] = {
        let takeAction = UIPreviewAction(title: "Take Dose", style: .default) { (action: UIPreviewAction, vc: UIViewController) -> Void in
            if let med = self.med {
                let dose = Dose(insertInto: self.cdStack.context)
                dose.date = Date()
                dose.dosage = med.dosage
                dose.dosageUnit = med.dosageUnit
                med.addDose(dose)
                
                // Check if medication needs to be refilled
                let refillTime = self.defaults.integer(forKey: "refillTime")
                if med.needsRefill(limit: refillTime) {
                    med.sendRefillNotification()
                }
                
                self.cdStack.save()
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
            }
        }
        
        return [takeAction]
    }()
    
    
    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if med != nil {
            return true
        }
        
        // Deselect selected row
        if let index = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: index, animated: true)
        }
        
        return false
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if med != nil {
            if segue.identifier == "editMedication" {
                if let vc = segue.destination.childViewControllers[0] as? AddMedicationTVC {
                    vc.med = self.med
                    vc.editMode = true
                    if let index = sender as? IndexPath, index == Rows.name.index() {
                        vc.editName = true
                    }
                }
            }
            
            if segue.identifier == "addDose" {
                if let vc = segue.destination.childViewControllers[0] as? AddDoseTVC {
                    vc.med = self.med
                }
            }
            
            if segue.identifier == "refillPrescription" {
                if let vc = segue.destination.childViewControllers[0] as? AddRefillTVC {
                    vc.med = self.med
                }
            }
            
            if segue.identifier == "viewDoseHistory" {
                if let vc = segue.destination as? MedicineDoseHistoryTVC {
                    vc.med = self.med
                }
            }
            
            if segue.identifier == "viewRefillHistory" {
                if let vc = segue.destination as? MedicineRefillHistoryTVC {
                    vc.med = self.med
                }
            }
        }
    }

}


private enum Rows: Int {
    case none = -1
    case name
    case nextDose
    case doseDetails
    case prescriptionCount
    case actions
    case doseHistory
    case refillHistory
    case notes
    case delete
    
    init(index: IndexPath) {
        var row = Rows.none
        
        switch (index.section, index.row) {
        case (0, 0):
            row = Rows.name
        case (0, 1):
            row = Rows.nextDose
        case (0, 2):
            row = Rows.doseDetails
        case (0, 3):
            row = Rows.prescriptionCount
        case (0, 4):
            row = Rows.actions
        case (0, 5):
            row = Rows.doseHistory
        case (0, 6):
            row = Rows.refillHistory
        case (1, 0):
            row = Rows.notes
        case (2, 0):
            row = Rows.delete
        default:
            row = Rows.none
        }
        
        self = row
    }
    
    func index() -> IndexPath {
        switch self {
        case .name:
            return IndexPath(row: 0, section: 0)
        case .nextDose:
            return IndexPath(row: 1, section: 0)
        case .doseDetails:
            return IndexPath(row: 2, section: 0)
        case .prescriptionCount:
            return IndexPath(row: 3, section: 0)
        case .actions:
            return IndexPath(row: 4, section: 0)
        case .doseHistory:
            return IndexPath(row: 5, section: 0)
        case .refillHistory:
            return IndexPath(row: 6, section: 0)
        case .notes:
            return IndexPath(row: 0, section: 1)
        case .delete:
            return IndexPath(row: 0, section: 2)
        default:
            return IndexPath(row: 0, section: 0)
        }
    }
}
