//
//  AddRefillTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-31.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class AddRefillTVC: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    var med: Medicine?
    var refill: Refill
    
    
    // MARK: - Outlets
    
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var prescriptionCountLabel: UILabel!
    @IBOutlet var quantityInput: UITextField!
    @IBOutlet var quantityUnitLabel: UILabel!
    @IBOutlet var quantityUnitPicker: UIPickerView!
    @IBOutlet var conversionLabel: UILabel!
    @IBOutlet var conversionInput: UITextField!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var picker: UIDatePicker!

    
    // MARK: - Helper variables
    let cdStack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    let cal = Calendar.current
    let dateFormatter = DateFormatter()
    fileprivate var selectedRow = Rows.none

    
    // MARK: - Initialization
    
    required init?(coder aDecoder: NSCoder) {
        refill = Refill(context: cdStack.context)
        refill.date = Date()
        
        // Setup date formatter
        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.dateStyle = DateFormatter.Style.none
        
        super.init(coder: aDecoder)
    }
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        
        // Modify VC
        self.view.tintColor = UIColor.medRed
        
        // Set picker min/max values
        picker.maximumDate = Date()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set values
        if let med = med {
            // Set title
            self.navigationItem.title = "Log Refill"
                
            // Set refill parameters
            if let prev = med.refillHistory?.array.last as? Refill {
                refill.quantity = prev.quantity
                refill.quantityUnit = prev.quantityUnit
                refill.conversion = prev.conversion
            } else {
                refill.quantity = 1.0
                refill.quantityUnit = med.dosageUnit
                refill.conversion = 1.0
            }

            refill.date = Date()
        }

        updateLabels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated) 
        quantityInput.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateLabels() {
        quantityInput.text = String(format:"%g", refill.quantity)
        quantityUnitLabel.text = refill.quantityUnit.description
        quantityUnitPicker.selectRow(Int(refill.quantityUnitInt), inComponent: 0, animated: false)

        if let med = med {
            conversionLabel.text = "\(med.dosageUnit.description) / \(refill.quantityUnit.description)"
            conversionInput.text = String(format:"%g", refill.conversion)
        }
        
        dateLabel.text = dateFormatter.string(from: refill.date)
        
        // Update description
        updateDescription()
        
        // Disable save button if no medication selected
        updateSave()
    }
    
    func updateDescription() {
        if let med = med {
            var refillGuide: String
            
            if refill.quantityUnit != med.dosageUnit && refill.conversion != 0 {
                let count = refill.quantity * refill.conversion
                refillGuide = med.refillStatus(entry: true, conversion: true)
                refillGuide += "\nThis will add \(count.removeTrailingZero()) \(med.dosageUnit.units(count))."
            } else {
                refillGuide = med.refillStatus(entry: true, conversion: false)
                
                if let count = med.refillHistory?.count, count > 0 {
                    let count = refill.quantity
                    refillGuide += "\nThis will add \(count.removeTrailingZero()) \(med.dosageUnit.units(count))."
                }
            }
            
            prescriptionCountLabel.text = refillGuide
        }
    }
    
    func updateSave() {
        if med == nil || refill.conversion == 0 {
            saveButton.isEnabled = false
        } else {
            saveButton.isEnabled = true
        }
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = Rows(index: indexPath)
        
        switch row {
        case Rows.refillUnitPicker:
            if selectedRow == Rows.refillUnit {
                return 175
            }
        case Rows.conversionAmount:
            if med?.dosageUnit != refill.quantityUnit {
                return tableView.rowHeight
            }
        case Rows.datePicker:
            if selectedRow == Rows.date {
                return 216
            }
        default:
            return tableView.rowHeight
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let row = Rows(index: indexPath)
        
        cell.preservesSuperviewLayoutMargins = true
        cell.layoutMargins = tableView.layoutMargins
        cell.separatorInset = tableView.separatorInset
        
        if selectedRow == Rows(index: indexPath) {
            cell.detailTextLabel?.textColor = UIColor.medRed
        } else {
            cell.detailTextLabel?.textColor = UIColor.gray
        }
        
        switch(row) {
        case Rows.refillUnit:
            if row != selectedRow && med?.dosageUnit == refill.quantityUnit {
                cell.preservesSuperviewLayoutMargins = false
                cell.layoutMargins = UIEdgeInsets.zero
                cell.separatorInset = UIEdgeInsets.zero
                cell.contentView.layoutMargins = tableView.separatorInset
            }
        case Rows.refillUnitPicker:
            if med?.dosageUnit == refill.quantityUnit {
                print("Unit picker issue!")
                cell.preservesSuperviewLayoutMargins = false
                cell.layoutMargins = UIEdgeInsets.zero
                cell.separatorInset = UIEdgeInsets.zero
                cell.contentView.layoutMargins = tableView.separatorInset
            }
        case Rows.date:
            if row != selectedRow {
                cell.preservesSuperviewLayoutMargins = false
                cell.layoutMargins = UIEdgeInsets.zero
                cell.separatorInset = UIEdgeInsets.zero
                cell.contentView.layoutMargins = tableView.separatorInset
            }
        default: break
        }
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
        
        let newSelect = Rows(index: indexPath)
        
        if selectedRow == newSelect {
            selectedRow = Rows.none
        } else {
            selectedRow = newSelect
        }
        
        // Reload labels
        let labels = [Rows.refillUnit.index(), Rows.date.index()]
        tableView.reloadRows(at: labels, with: .none)
        
        // Reload table
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    // MARK: - Text input delegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        selectedRow = Rows.none
        
        // Reload labels
        let labels = [Rows.refillUnit.index(), Rows.date.index()]
        tableView.reloadRows(at: labels, with: .none)
        
        // Reload table
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    
    // MARK: - Picker data source
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Doses.count
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30.0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Doses(rawValue: Int16(row))?.description
    }
    
    
    // MARK: - Picker delegate
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let unit = Doses(rawValue: Int16(row)) {
            if unit != refill.quantityUnit {
                refill.quantityUnit = unit
                refill.conversion = 1
            }
            
            tableView.reloadRows(at: [Rows.refillUnitPicker.index()], with: .none)
        
            updateLabels()
            
            // Reload table view
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func updateDate(_ sender: UIDatePicker) {
        refill.date = sender.date
            
        if sender.date.isMidnight() {
            dateLabel.text = "Midnight"
        } else {
            dateLabel.text = dateFormatter.string(from: sender.date)
        }
    }
    
    @IBAction func updateQuantity(_ sender: UITextField) {
        if let value = sender.text {
            refill.quantity = (value as NSString).floatValue
            updateDescription()
        }
    }
    
    @IBAction func updateConversion(_ sender: UITextField) {
        if let value = sender.text {
            refill.conversion = (value as NSString).floatValue
            updateDescription()
            updateSave()
        }
    }

    @IBAction func correctConversion(_ sender: UITextField) {
        if let value = sender.text {
            var val = (value as NSString).floatValue
            if val == 0 { val = 1 }
            
            refill.conversion = val
            updateLabels()
        }
    }
    
    
    // MARK: - Navigation
    
    @IBAction func saveRefill(_ sender: AnyObject) {
        med?.addRefill(refill)
        refill.medicine = med
        
        cdStack.save()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelRefill(_ sender: AnyObject) {
        cdStack.context.delete(refill)
        cdStack.save()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
        
        dismiss(animated: true, completion: nil)
    }
    
}


private enum Rows: Int {
    case none = -1
    case refillQuantity
    case refillUnit
    case refillUnitPicker
    case conversionAmount
    case date
    case datePicker
    
    init(index: IndexPath) {
        var row = Rows.none
        
        switch (index.section, index.row) {
        case (0, 0):
            row = Rows.refillQuantity
        case (0, 1):
            row = Rows.refillUnit
        case (0, 2):
            row = Rows.refillUnitPicker
        case (0, 3):
            row = Rows.conversionAmount
        case (1, 0):
            row = Rows.date
        case (1, 1):
            row = Rows.datePicker
        default:
            row = Rows.none
        }
        
        self = row
    }
    
    func index() -> IndexPath {
        switch self {
        case .refillQuantity:
            return IndexPath(row: 0, section: 0)
        case .refillUnit:
            return IndexPath(row: 1, section: 0)
        case .refillUnitPicker:
            return IndexPath(row: 2, section: 0)
        case .conversionAmount:
            return IndexPath(row: 3, section: 0)
        case .date:
            return IndexPath(row: 0, section: 1)
        case .datePicker:
            return IndexPath(row: 1, section: 1)
        default:
            return IndexPath(row: 0, section: 0)
        }
    }
}
