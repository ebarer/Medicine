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
    
    weak var med: Medicine?
    
    // MARK: - Outlets
    @IBOutlet var nameCell: UITableViewCell!
    @IBOutlet var nameIcon: UIImageView!
    @IBOutlet var nameIconWidth: NSLayoutConstraint!
    @IBOutlet var nameLabelLeading: NSLayoutConstraint!
    @IBOutlet var nameLabel: UILabel!
    
    @IBOutlet var doseDetailsLabel: UILabel!
    
    @IBOutlet var doseTitle: UILabel!
    @IBOutlet var doseLabel: UILabel!
    
    @IBOutlet var prescriptionStack: UIStackView!
    @IBOutlet var prescriptionLabel: UILabel!
    @IBOutlet var prescriptionDescription: UILabel!
    
    @IBOutlet var takeDoseButton: UIButton!
    @IBOutlet var actionCell: UITableViewCell!
    @IBOutlet var refillButton: UIButton!
    @IBOutlet var actionsButton: UIButton!
    
    @IBOutlet var notesField: UITextView!
    
    // MARK: - Helper variables
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine")!
    
    let cal = Calendar.current
    let dateFormatter = DateFormatter()
    
    static let fullNameIconWidth: CGFloat = 25.0
    static let fullNameLeadingPadding: CGFloat = 12.0
    static let prescriptionCellHeightMin: CGFloat = 75.0
    static let actionCellHeight: CGFloat = 100.0
    static let notesCellHeightMin: CGFloat = 50.0
    
    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.cellLayoutMarginsFollowReadableWidth = true
        
        // Setup edit button
        let editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editMedication))
        self.navigationItem.rightBarButtonItem = editButton
        
        // Add observeres for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(refreshDetails), name: NSNotification.Name(rawValue: "refreshView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(medicationDeleted), name: NSNotification.Name(rawValue: "medicationDeleted"), object: nil)
        
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
        
        notesField.isScrollEnabled = false
        
        // Update actions
        takeDoseButton.layer.cornerRadius = 10.0
        refillButton.layer.cornerRadius = 10.0
        
        displayEmptyView()
        updateLabels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadSections(IndexSet(integer: Rows.name.index().section), with: .none)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.refreshDetails()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func refreshDetails() {
        // Select first medication if none selected
        displayEmptyView()
        updateLabels()
        
        tableView.reloadRows(at: [Rows.name.index(), Rows.nextDose.index()], with: .none)
    }
    
    @objc func medicationDeleted() {
        self.med = nil;
        refreshDetails()
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
        
        if let index = tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: index, animated: true)
        }
    }
    
    func updateLabels() {
        if let med = med {
            nameLabel.text = med.name
            nameLabel.font = UIFont.preferredFont(for: .largeTitle, weight: .semibold)
            
            var detailsString = "\(med.dosage.removeTrailingZero()) \(med.dosageUnit.units(med.dosage))"
                detailsString += ", every \(med.intervalLabel())"
            
            doseDetailsLabel.text = detailsString
            
            if #available(iOS 13.0, macCatalyst 13.0, *) {
                nameLabel.textColor = UIColor.label
            } else {
                nameLabel.textColor = UIColor.black
            }
            
            updateDose()
            updatePrescription()
            
            notesField.text = med.notes
        }
    }
    
    func updateDose() {
        if let med = med {
            // Set defaults
            nameIcon.image = nil
            nameIcon.tintColor = UIColor.medRed
            nameIconWidth.constant = 0
            nameLabelLeading.constant = 0
            
            doseTitle.textColor = UIColor.medGray2
            doseTitle.text = "Next Dose"
            
            if #available(iOS 13.0, macCatalyst 13.0, *) {
                doseDetailsLabel.textColor = UIColor.label
                doseLabel.textColor = UIColor.label
            } else {
                doseDetailsLabel.textColor = UIColor.black
                doseLabel.textColor = UIColor.black
            }
            
            // If no doses taken
            if med.doseHistory?.count == 0 && med.intervalUnit == .hourly {
                doseTitle.text = "No doses logged"
                doseLabel.text?.removeAll()
            }
            
            // If reminders aren't enabled for medication
            else if med.reminderEnabled == false {
                if let date = med.nextDose {
                    if date.compare(Date()) == .orderedAscending {
                        doseTitle.text = "Next Dose"
                        doseLabel.text = "Take as needed"
                    } else {
                        doseTitle.text = "Next Dose"
                        doseLabel.text = Medicine.dateString(date)
                    }
                } else {
                    doseTitle.text = "No doses logged"
                    doseLabel.text?.removeAll()
                }
            } else {
                // If medication is overdue, set subtitle to next dosage date and tint red
                if med.isOverdue().flag {
                    nameIcon.image = UIImage(named: "OverdueIcon")
                    nameIconWidth.constant = MedicineDetailsTVC.fullNameIconWidth
                    nameLabelLeading.constant = MedicineDetailsTVC.fullNameLeadingPadding
                    nameLabel.textColor = UIColor.medRed
                    
                    doseTitle.textColor = UIColor.medRed
                    doseTitle.text = "Overdue"

                    if let date = med.isOverdue().overdueDose {
                        doseLabel.textColor = UIColor.medRed
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
    
    func updatePrescription() {
        guard let med = med,
              let historyCount = med.refillHistory?.count,
              historyCount > 0
        else {
            prescriptionLabel.text = "None"
            return
        }
        
        if #available(iOS 13.0, macCatalyst 13.0, *) {
            prescriptionLabel.textColor = UIColor.label
        } else {
            prescriptionLabel.textColor = UIColor.black
        }

        let count = med.prescriptionCount
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        
        if count.isZero {
            prescriptionLabel.text = "None remaining"
        } else if let count = numberFormatter.string(from: NSNumber(value: count)) {
            prescriptionLabel.text = "\(count) \(med.dosageUnit.units(med.prescriptionCount)) remaining"
        }
        
        if med.prescriptionCount < med.dosage {
            prescriptionDescription.text = "You do not appear to have enough \(med.name!) remaining to take the next dose. "
        } else {
            if let days = med.refillDaysRemaining() {
                if days <= 1 {
                    prescriptionDescription.text = "You will need to refill after the next dose. "
                } else {
                    prescriptionDescription.text = "Based on current usage, your prescription should last approximately \(days) \(Intervals.daily.units(Float(days))). "
                }
            } else {
                prescriptionDescription.text = "Continue taking doses to receive an approximation for your prescription duration."
            }
        }
    }
    
    // MARK: - Button events
    @IBAction func touchDown(_ sender: UIButton) {
        switch (sender.tag) {
        case Actions.takeDose.rawValue:
            sender.layer.backgroundColor = UIColor.actionDoseHighlighted.cgColor
        case Actions.refill.rawValue:
            sender.layer.backgroundColor = UIColor.actionRefillHighlighted.cgColor
        default:
            break
        }
    }
    
    @IBAction func touchUp(_ sender: UIButton) {
        switch (sender.tag) {
        case Actions.takeDose.rawValue:
            sender.layer.backgroundColor = UIColor.actionDose.cgColor
        case Actions.refill.rawValue:
            sender.layer.backgroundColor = UIColor.actionRefill.cgColor
        default:
            break
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == Rows.name.index().section {
            return tableView.sectionHeaderHeight
        }
        
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == Rows.notes.index().section && med != nil {
            return "Notes"
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightForIndexPath(indexPath)
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightForIndexPath(indexPath)
    }
    
    func heightForIndexPath(_ indexPath: IndexPath) -> CGFloat {
        switch Rows(index: indexPath) {
        case Rows.prescriptionCount:
            guard let count = med?.refillHistory?.count, count > 0 else {
                return 0.0
            }
            
            prescriptionLabel.sizeToFit()
            let labelBounds = prescriptionLabel.frame
            let constraintRect = CGSize(width: tableView.frame.width, height: .greatestFiniteMagnitude)
            let descriptionBounds = prescriptionDescription.sizeThatFits(constraintRect)
            let contentHeight = labelBounds.height + 15.0 + descriptionBounds.height
            return max(contentHeight * 1.5, MedicineDetailsTVC.prescriptionCellHeightMin)
        case Rows.actions:
            return MedicineDetailsTVC.actionCellHeight
        case Rows.notes:
            let notesSize = notesField.sizeThatFits(notesField.frame.size)
            let notesBottomPadding = notesField.font?.pointSize ?? UIFont.preferredFont(forTextStyle: .body).pointSize
            return max(notesSize.height, MedicineDetailsTVC.notesCellHeightMin) + notesBottomPadding
        default:
            return UITableView.automaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.preservesSuperviewLayoutMargins = true
        
        switch Rows(index: indexPath) {
        case Rows.nextDose:
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
        CoreDataStack.shared.save()

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
        
        let alert = UIAlertController(title: med.name, message: dateString, preferredStyle: UIAlertController.Style.actionSheet)
        
        if med.isOverdue().flag {
            alert.addAction(UIAlertAction(title: "Snooze Dose", style: UIAlertAction.Style.default, handler: {(action) -> Void in
                med.snoozeNotification()
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Skip Dose", style: UIAlertAction.Style.destructive, handler: {(action) -> Void in
            med.skipDose(context: CoreDataStack.shared.context)
            CoreDataStack.shared.save()
            
            // Update spotlight index values and home screen shortcuts
            self.appDelegate.indexMedication()
            self.appDelegate.setDynamicShortcuts()
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
        }))
        
        // If last dose is set, allow user to undo last dose
        if (med.lastDose != nil) {
            alert.addAction(UIAlertAction(title: "Undo Last Dose", style: UIAlertAction.Style.destructive, handler: {(action) -> Void in
                med.untakeLastDose(context: CoreDataStack.shared.context)
                CoreDataStack.shared.save()
                    
                // Update spotlight index values and home screen shortcuts
                self.appDelegate.indexMedication()
                self.appDelegate.setDynamicShortcuts()
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel))
        
        // Set popover for iPad
        alert.popoverPresentationController?.sourceView = actionsButton
        alert.popoverPresentationController?.sourceRect = actionsButton.bounds.offsetBy(dx: -1, dy: 4)
        alert.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
        
        alert.view.layoutIfNeeded()
        alert.view.tintColor = UIColor.alertTint
        present(alert, animated: true, completion: nil)
    }

    func presentDeleteAlert(_ indexPath: IndexPath) {
        if let med = med {
            if let name = med.name {
                let deleteAlert = UIAlertController(title: "Delete \(name)?", message: "This will permanently delete \(name) and all of its history.", preferredStyle: UIAlertController.Style.alert)
                
                deleteAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: {(action) -> Void in
                    self.tableView.deselectRow(at: indexPath, animated: true)
                }))
                
                deleteAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: {(action) -> Void in
                    self.deleteMed()
                }))
                
                deleteAlert.view.tintColor = UIColor.alertTint
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
            CoreDataStack.shared.context.delete(med)
            CoreDataStack.shared.save()

            // Send notifications
            NotificationCenter.default.post(name: Notification.Name(rawValue: "medicationDeleted"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
        }
    }
    
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
                if let vc = segue.destination.children[0] as? AddMedicationTVC {
                    vc.med = self.med
                    vc.editMode = true
                    if let index = sender as? IndexPath, index == Rows.name.index() {
                        vc.editName = true
                    }
                }
            }
            
            if segue.identifier == "addDose" {
                if let vc = segue.destination.children[0] as? AddDoseTVC {
                    vc.med = self.med
                }
            }
            
            if segue.identifier == "refillPrescription" {
                if let vc = segue.destination.children[0] as? AddRefillTVC {
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
    case doseDetails
    case nextDose
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
            row = Rows.doseDetails
        case (0, 2):
            row = Rows.nextDose
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
        case .doseDetails:
            return IndexPath(row: 1, section: 0)
        case .nextDose:
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

private enum Actions: Int {
    case takeDose = 0
    case refill = 1
}
