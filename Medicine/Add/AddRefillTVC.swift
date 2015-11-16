//
//  AddRefillTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-31.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class AddRefillTVC: UITableViewController, UIPickerViewDelegate, UITextFieldDelegate {
    
    var med: Medicine?
    var refill: Prescription
    
    
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
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext
    
    let cal = NSCalendar.currentCalendar()
    let dateFormatter = NSDateFormatter()
    private var selectedRow = Rows.none

    
    // MARK: - Initialization
    
    required init?(coder aDecoder: NSCoder) {
        // Setup context
        moc = appDelegate.managedObjectContext
        
        // Setup date formatter
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
        
        let entity = NSEntityDescription.entityForName("Prescription", inManagedObjectContext: moc)
        refill = Prescription(entity: entity!, insertIntoManagedObjectContext: moc)
        
        super.init(coder: aDecoder)
    }
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        
        // Modify VC
        self.view.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        
        // Set picker min/max values
        picker.maximumDate = NSDate()
    }
    
    override func viewWillAppear(animated: Bool) {
        // Set values
        if let med = med {
            // Set title
            self.navigationItem.title = "Refill \(med.name!)"
            
            // Set description
            prescriptionCountLabel.text = med.refillStatus(entry: true)
                
            // Set refill parameters
            if let prev = med.refillHistory?.array.last as? Prescription {
                refill.quantity = prev.quantity
                refill.quantityUnit = prev.quantityUnit
                refill.conversion = prev.conversion
            } else {
                refill.quantity = 1.0
                refill.quantityUnit = med.dosageUnit
                refill.conversion = 1.0
            }

            refill.date = NSDate()
        }

        updateLabels()
    }
    
    override func viewDidAppear(animated: Bool) {
        quantityInput.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
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
        
        dateLabel.text = dateFormatter.stringFromDate(refill.date)
        
        // Disable save button if no medication selected
        if med == nil {
            saveButton.enabled = false
        } else {
            saveButton.enabled = true
        }
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = Rows(index: indexPath)
        
        switch(row) {
        case Rows.quantityUnitPicker:
            if selectedRow == Rows.quantityUnit {
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
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let row = Rows(index: indexPath)
        
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsetsZero
        cell.separatorInset = UIEdgeInsetsMake(0, 15, 0, 0)
        
        if selectedRow == Rows(index: indexPath) {
            cell.detailTextLabel?.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        } else {
            cell.detailTextLabel?.textColor = UIColor.grayColor()
        }
        
        switch(row) {
        case Rows.quantityUnit:
            if row != selectedRow {
                cell.separatorInset = UIEdgeInsetsZero
            }
        case Rows.quantityUnitPicker:
            if med?.dosageUnit == refill.quantityUnit {
                cell.separatorInset = UIEdgeInsetsZero
            }
        case Rows.date:
            if row != selectedRow {
                cell.separatorInset = UIEdgeInsetsZero
            }
        default: break
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if let med = med where section == 0 {
            if refill.quantityUnit != med.dosageUnit {
                let count = refill.quantity * refill.conversion
                return "This will add \(count) \(med.dosageUnit.units(count))."
            }
        }
        
        return nil
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.view.endEditing(true)
        
        let newSelect = Rows(index: indexPath)
        
        if selectedRow == newSelect {
            selectedRow = Rows.none
        } else {
            selectedRow = newSelect
        }
        
        // Reload labels
        let labels = [Rows.quantityUnit.index(), Rows.date.index()]
        tableView.reloadRowsAtIndexPaths(labels, withRowAnimation: .None)
        
        // Reload table
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    // MARK: - Text input delegate
    
    func textFieldDidBeginEditing(textField: UITextField) {
        selectedRow = Rows.none
        
        // Reload labels
        let labels = [Rows.quantityUnit.index(), Rows.date.index()]
        tableView.reloadRowsAtIndexPaths(labels, withRowAnimation: .None)
        
        // Reload table
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    
    // MARK: - Picker data source
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Doses.count
    }
    
    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30.0
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Doses(rawValue: Int16(row))?.description
    }
    
    
    // MARK: - Picker delegate
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let unit = Doses(rawValue: Int16(row)) {
            refill.quantityUnit = unit
        }
        
        updateLabels()
        
        // Reload table view
        tableView.reloadRowsAtIndexPaths([Rows.quantityUnitPicker.index()], withRowAnimation: .None)
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    // MARK: - Actions
    
    @IBAction func updateDate(sender: UIDatePicker) {
        refill.date = sender.date
            
        if sender.date.isMidnight() {
            dateLabel.text = "Midnight"
        } else {
            dateLabel.text = dateFormatter.stringFromDate(sender.date)
        }
    }
    
    @IBAction func updateQuantity(sender: UITextField) {
        if let value = sender.text {
            let val = (value as NSString).floatValue
            refill.quantity = val
        }
    }
    
    @IBAction func updateConversion(sender: UITextField) {
        if let value = sender.text {
            let val = (value as NSString).floatValue
            refill.conversion = val
        }
    }

    
    // MARK: - Navigation
    
    @IBAction func saveRefill(sender: AnyObject) {
        med?.addRefill(refill)
        refill.medicine = med
        
        appDelegate.saveContext()
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancelRefill(sender: AnyObject) {
        moc.deleteObject(refill)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}


private enum Rows: Int {
    case none = -1
    case quantityAmount
    case quantityUnit
    case quantityUnitPicker
    case conversionAmount
    case date
    case datePicker
    
    init(index: NSIndexPath) {
        var row = Rows.none
        
        switch (index.section, index.row) {
        case (0, 0):
            row = Rows.quantityAmount
        case (0, 1):
            row = Rows.quantityUnit
        case (0, 2):
            row = Rows.quantityUnitPicker
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
    
    func index() -> NSIndexPath {
        switch self {
        case .quantityAmount:
            return NSIndexPath(forRow: 0, inSection: 0)
        case .quantityUnit:
            return NSIndexPath(forRow: 1, inSection: 0)
        case .quantityUnitPicker:
            return NSIndexPath(forRow: 2, inSection: 0)
        case .conversionAmount:
            return NSIndexPath(forRow: 3, inSection: 0)
        case .date:
            return NSIndexPath(forRow: 0, inSection: 1)
        case .datePicker:
            return NSIndexPath(forRow: 1, inSection: 1)
        default:
            return NSIndexPath(forRow: 0, inSection: 0)
        }
    }
}
