//
//  AddMedicationTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-27.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class AddMedicationTVC: UITableViewController, UITextFieldDelegate, UITextViewDelegate {
    
    var med: Medicine!
    var editMode: Bool = false
    var editName: Bool = false
    
    
    // MARK: - Outlets
    
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var medicationName: UITextField!
    @IBOutlet var dosageLabel: UILabel!
    @IBOutlet var reminderToggle: UISwitch!
    @IBOutlet var intervalLabel: UILabel!
    @IBOutlet var prescriptionLabel: UILabel!
    
    
    // MARK: - Helper variables
    
    let cdStack = (UIApplication.shared.delegate as! AppDelegate).stack
    let cal = Calendar.current
    let dateFormatter = DateFormatter()

    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        
        let placeholder = NSAttributedString(string: "Enter medication name",
                                             attributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 32.0, weight: .light)])
        self.medicationName.attributedPlaceholder = placeholder
        self.medicationName.delegate = self
        
        // Setup date formatter
        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.dateStyle = DateFormatter.Style.none
        
        // Modify VC
        self.view.tintColor = UIColor.medRed
        
        // Setup medicine object
        if editMode == false {
            med = Medicine(insertInto: cdStack.context)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect selected row
        if let index = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: index, animated: animated)
        }
        
        if !editMode {
            self.title = "New Medication"
        } else {
            self.title = "Edit Medication"
            prescriptionLabel.text = "Refill Prescription"
        }
        
        updateLabels()

        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if med.name == nil || med.name?.isEmpty == true || editName {
            medicationName.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateLabels() {
        // Set name label
        medicationName.text = med.name
        
        // Set dosage label
        dosageLabel.text = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
        
        // Set reminder toggle
        reminderToggle.isOn = med.reminderEnabled
        
        // Set interval label
        intervalLabel.text = "Every " + med.intervalLabel()
        
        // If medication has no name, disable save button
        if med.name == nil || med.name?.isEmpty == true {
            saveButton.isEnabled = false
        } else {
            saveButton.isEnabled = true
        }
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if editMode {
            return 4
        }
        
        return 3
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case Rows.name.index().section:
            return tableView.sectionHeaderHeight
        case Rows.prescription.index().section:
            if med.name != nil && med.name != "" {
                return tableView.sectionHeaderHeight
            }
        case Rows.delete.index().section:
            return tableView.sectionHeaderHeight + 10.0
        default:
            return UITableViewAutomaticDimension
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch Rows(index: indexPath) {
        case Rows.name:
            return 70.0
        case Rows.prescription:
            if med.name != nil && med.name != "" {
                return 50.0
            } else {
                return 0
            }
        default:
            break
        }
        
        return 50.0
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.preservesSuperviewLayoutMargins = true
        
        switch Rows(index: indexPath) {
        case Rows.dosage:
            if med.reminderEnabled == false {
                cell.separatorInset = UIEdgeInsets.zero
            }
        default: break
        }
    }
    
//    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        switch section {
//        case Rows.prescription.index().section:
//            if med.name != nil && med.name != "" {
//                return 60.0
//            }
//        default:
//            return UITableViewAutomaticDimension
//        }
//
//        return 0
//    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == Rows.prescription.index().section {
            if let count = med.refillHistory?.count, count > 0 {
                return med.refillStatus()
            } else if med.name != nil && med.name != "" {
                return "Keep track of your prescription levels, and be reminded to refill when running low."
            }
        }
        
        return nil
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = Rows(index: indexPath)
        
        switch(row) {
        case Rows.delete:
            presentDeleteAlert(indexPath)
        default: break
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let row = Rows(index: indexPath)
        
        switch row {
        case Rows.prescription:
            if med.name == nil || med.name == "" {
                return false
            }
        default:
            return true
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    // MARK: - Actions
    
    @IBAction func updateName(_ sender: UITextField) {
        let temp = med.name
        med.name = sender.text
        updateLabels()
        
        // Reload table view
        if temp == nil || temp == "" || sender.text!.isEmpty {
            tableView.reloadSections(IndexSet(integer: Rows.prescription.index().section), with: UITableViewRowAnimation.automatic)
            tableView.beginUpdates()
            tableView.endUpdates()
        } else {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    @IBAction func toggleReminder(_ sender: UISwitch) {
        med.reminderEnabled = sender.isOn

        // Update rows
        tableView.reloadRows(at: [Rows.dosage.index()], with: UITableViewRowAnimation.none)
        tableView.beginUpdates()
        tableView.endUpdates()
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
            
            // Remove medication from persistent store
            cdStack.context.delete(med)
            cdStack.save()
            
            // Send notifications
            NotificationCenter.default.post(name: Notification.Name(rawValue: "medicationDeleted"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
        }
    }
    
    
    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if med.name == nil || med.name == "" {
            if identifier == "refillPrescription" {
                return false
            }
        }
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "setDosage" {
            if let vc = segue.destination as? AddMedicationTVC_Dosage {
                vc.med = self.med
                vc.editMode = self.editMode
            }
        }
        
        if segue.identifier == "setInterval" {
            if let vc = segue.destination as? AddMedicationTVC_Interval {
                vc.med = self.med
                vc.editMode = self.editMode
            }
        }
        
        if segue.identifier == "refillPrescription" {
            if let vc = segue.destination.childViewControllers[0] as? AddRefillTVC {
                if let index = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: index, animated: false)
                }
                
                vc.med = self.med
            }
        }
    }
    
    @IBAction func saveMedication(_ sender: AnyObject?) {
        if !editMode {
            let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
            if let count = try? cdStack.context.count(for: request) {
                med.sortOrder = Int16(count)
            }
        } else {
            if let lastDose = med.lastDose {
                do {
                    lastDose.next = try med.calculateNextDose(lastDose.date)
                } catch {
                    print("Unable to update last dose")
                }
            }
        }
        
        cdStack.save()
        
        // Reschedule next notification
        med.scheduleNextNotification()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelMedication(_ sender: AnyObject?) {
        if !editMode {
            cdStack.context.delete(med)
        } else {
            cdStack.context.rollback()
        }
        
        cdStack.save()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
        
        dismiss(animated: true, completion: nil)
    }
    
}


private enum Rows: Int {
    case none = -1
    case name
    case reminderEnable
    case dosage
    case interval
    case prescription
    case delete
    
    init(index: IndexPath) {
        var row = Rows.none
        
        switch (index.section, index.row) {
        case (0, 0):
            row = Rows.name
        case (0, 1):
            row = Rows.reminderEnable
        case (1, 0):
            row = Rows.dosage
        case (1, 1):
            row = Rows.interval
        case (2, 0):
            row = Rows.prescription
        case (3, 0):
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
        case .reminderEnable:
            return IndexPath(row: 1, section: 0)
        case .dosage:
            return IndexPath(row: 0, section: 1)
        case .interval:
            return IndexPath(row: 1, section: 1)
        case .prescription:
            return IndexPath(row: 0, section: 2)
        case .delete:
            return IndexPath(row: 0, section: 3)
        default:
            return IndexPath(row: 0, section: 0)
        }
    }
}
