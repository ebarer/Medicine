//
//  AddDoseTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-31.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class AddDoseTVC: UITableViewController {
    
    var med: Medicine?
    var dose: Dose
    var initialDosageAmount: Float?

    
    // MARK: - Outlets
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var picker: UIDatePicker!
    @IBOutlet var medCell: UITableViewCell!
    @IBOutlet var medLabel: UILabel!
    @IBOutlet var doseCell: UITableViewCell!
    @IBOutlet var doseLabel: UILabel!
    @IBOutlet var prescriptionCell: UITableViewCell!
    
    
    // MARK: - Helper variables
    let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine")!
    
    let cal = Calendar.current
    let dateFormatter = DateFormatter()
    var globalHistory: Bool = false
    
    
    // MARK: - Initialization
    required init?(coder aDecoder: NSCoder) {
        // Setup date formatter
        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.dateStyle = DateFormatter.Style.none

        dose = Dose(insertInto: CoreDataStack.shared.context)
        dose.date = Date()
        
        super.init(coder: aDecoder)
    }
    
    
    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        
        if #available(iOS 13.0, macCatalyst 13.0, *) {
            self.navigationController?.isModalInPresentation = true
        }
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()

        // Modify VC
        self.view.tintColor = UIColor.medRed

        // Prevent modification of medication when not in global history
        if !globalHistory {
            medCell.accessoryType = UITableViewCell.AccessoryType.none
            medCell.selectionStyle = UITableViewCell.SelectionStyle.none
        }
        
        // Preserve dosage amount in case of cancel
        initialDosageAmount = med?.dosage

        // Set picker min/max values
        picker.maximumDate = Date()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect selected row
        if let index = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: index, animated: animated)
        }

        updateDoseValues()
        updateLabels()
        
        tableView.reloadData()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateDoseValues() {
        if let med = self.med {
            dose.medicine = med
            dose.dosage = med.dosage
            dose.dosageUnitInt = med.dosageUnitInt
        } else {
            let fetchRequest: NSFetchRequest<Medicine> = Medicine.fetchRequest()
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "reminderEnabled", ascending: false),
                NSSortDescriptor(key: "hasNextDose", ascending: false),
                NSSortDescriptor(key: "dateNextDose", ascending: true),
                NSSortDescriptor(key: "dateLastDose", ascending: false)
            ]
            
            if let med = (try? CoreDataStack.shared.context.fetch(fetchRequest))?.first {
                self.med = med
                dose.medicine = med
                dose.dosage = med.dosage
                initialDosageAmount = med.dosage
                dose.dosageUnitInt = med.dosageUnitInt
            }
        }
    }
    
    func updateLabels() {
        // If no medication selected, force user to select a medication
        if med == nil {
            medLabel.text = "None"
            doseLabel.text = "None"
            
            doseCell.selectionStyle = .none
            prescriptionCell.selectionStyle = .none
            saveButton.isEnabled = false
        } else {
            picker.setDate(dose.date as Date, animated: true)
            
            medLabel.text = med?.name
            doseLabel.text = String(format:"%g %@", dose.dosage, dose.dosageUnit.units(dose.dosage))
            
            doseCell.selectionStyle = .default
            prescriptionCell.selectionStyle = .default
            saveButton.isEnabled = true
        }
        
        // If insufficient prescription levels,
        // if dose.dosage > dose.medicine?.prescriptionCount {
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return tableView.sectionHeaderHeight
        }
        
        return UITableView.automaticDimension
    }
        
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightForIndexPath(indexPath)
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightForIndexPath(indexPath)
    }
    
    func heightForIndexPath(_ indexPath: IndexPath) -> CGFloat {
        if indexPath == IndexPath(row: 0, section: 0) {
            return 216.0
        }
        
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if let med = med, section == 0 {
            return med.refillStatus()
        }
        
        return nil
    }
    
    
    // MARK: - Actions
    @IBAction func updateDate(_ sender: UIDatePicker) {
        dose.date = sender.date
    }
    
    
    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // Prevent segues if no medication selected (except to select a medication)
        if med == nil && identifier != "selectMedicine" {
            return false
        }
        
        // Prevent changing medicine unless adding dose from global history view
        if !globalHistory && identifier == "selectMedicine" {
            return false
        }
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectMedicine" {
            if let vc = segue.destination as? AddDoseTVC_Medicine {
                vc.selectedMed = med
            }
        }
        
        if segue.identifier == "setDosage" {
            if let vc = segue.destination as? AddMedicationTVC_Dosage {
                vc.med = med
                vc.editMode = true
            }
        }
        
        if segue.identifier == "refillPrescription" {
            if let vc = segue.destination.children[0] as? AddRefillTVC {
                vc.med = med
                if let index = tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: index, animated: false)
                }
            }
        }
    }

    
    @IBAction func medicationUnwindSelect(_ unwindSegue: UIStoryboardSegue) {
        if let vc = unwindSegue.source as? AddDoseTVC_Medicine {
            self.med = vc.selectedMed
            self.initialDosageAmount = self.med?.dosage
        }
    }
    
    @IBAction func saveDose(_ sender: AnyObject?) {
        if let med = self.med {
            do {
                // Save dose
                try med.takeDose(dose)
                
                // Check if medication needs to be refilled
                let refillTime = defaults.integer(forKey: "refillTime")
                if med.needsRefill(limit: refillTime) {
                    med.sendRefillNotification()
                }
                
                CoreDataStack.shared.save()

                dismiss(animated: true, completion: nil)
            } catch {
                presentDoseAlert()
            }
        } else {
            presentMedAlert()
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
    }
    
    @IBAction func cancelDose(_ sender: AnyObject?) {
        CoreDataStack.shared.context.delete(dose)
        CoreDataStack.shared.save()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
        
        // On cancel, revert medication dosage
        if let initialDosageAmount = initialDosageAmount {
            med?.dosage = initialDosageAmount
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Error handling
    func presentMedAlert() {
        globalHistory = true
        let alert = UIAlertController(title: "Invalid Medication", message: "You have to select a valid medication.", preferredStyle: UIAlertController.Style.alert)
        alert.view.tintColor = UIColor.alertTint
        self.present(alert, animated: true, completion: nil)
    }
    
    func presentDoseAlert() {
        if let med = self.med {
            let doseAlert = UIAlertController(title: "Repeat Dose?", message: "You have logged a dose for \(med.name!) within the passed 5 minutes, do you wish to log another dose?", preferredStyle: UIAlertController.Style.alert)
            
            doseAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
            
            doseAlert.addAction(UIAlertAction(title: "Add Dose", style: UIAlertAction.Style.destructive, handler: {(action) -> Void in
                CoreDataStack.shared.save()
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
                
                self.dismiss(animated: true, completion: nil)
            }))
            
            doseAlert.view.tintColor = UIColor.alertTint
            self.present(doseAlert, animated: true, completion: nil)
        }
    }

}
