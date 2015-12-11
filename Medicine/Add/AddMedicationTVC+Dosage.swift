//
//  AddMedicationTVC+Dosage.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-01.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class AddMedicationTVC_Dosage: UITableViewController, UIPickerViewDelegate {
    
    var med: Medicine!
    var editMode: Bool = false
    
    
    // MARK: - Outlets
    
    @IBOutlet var dosageInput: UITextField!
    @IBOutlet var dosageUnitLabel: UILabel!
    @IBOutlet var dosageUnitPicker: UIPickerView!
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Modify VC
        self.view.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        
        // Set values
        dosageInput.text = String(format:"%g", med.dosage)

        dosageUnitLabel.text = med.dosageUnit.description
        dosageUnitPicker.selectRow(Int(med.dosageUnitInt), inComponent: 0, animated: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        dosageInput.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        dosageInput.resignFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath {
        case NSIndexPath(forRow: 2, inSection: 0):
            if editMode == false {
                return 162
            }
        default:
            return tableView.rowHeight
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.preservesSuperviewLayoutMargins = true

        switch indexPath {
        case NSIndexPath(forRow: 1, inSection: 0):
            if editMode == true {
                cell.preservesSuperviewLayoutMargins = false
                cell.layoutMargins = UIEdgeInsetsZero
                cell.separatorInset = UIEdgeInsetsZero
                cell.contentView.layoutMargins = UIEdgeInsetsMake(0, tableView.separatorInset.left, 0, tableView.separatorInset.left)
            }
        default: break
        }
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
            med.dosageUnit = unit
            dosageUnitLabel.text = unit.description
        }
    }
    
    
    // MARK: - Update dosage values
    
    @IBAction func updateDosage(sender: UITextField) {
        if let value = sender.text {
            med.dosage = (value as NSString).floatValue
        }
    }
    
}
