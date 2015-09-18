//
//  AddMedicationTVC+Dosage.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-01.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class AddMedicationTVC_Dosage: UITableViewController, UIPickerViewDelegate {
    
    weak var med: Medicine?
    
    
    // MARK: - Outlets
    
    @IBOutlet var dosageInput: UITextField!
    @IBOutlet var dosageUnitLabel: UILabel!
    @IBOutlet var dosageUnitPicker: UIPickerView!
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Modify VC
        self.view.tintColor = UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0)
        
        // Set values
        if let medicine = med {
            dosageInput.text = String(format:"%g", medicine.dosage)

            dosageUnitLabel.text = medicine.dosageUnit.units(medicine.dosage)
            dosageUnitPicker.selectRow(Int(medicine.dosageUnitInt), inComponent: 0, animated: false)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        dosageInput.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        dosageInput.resignFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
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
            med?.dosageUnit = unit
            dosageUnitLabel.text = unit.units(med?.dosage)
        }
    }
    
    
    // MARK: - Update dosage values
    
    @IBAction func updateDosage(sender: UITextField) {
        if let value = sender.text {
            let val = (value as NSString).floatValue            
            med?.dosage = val
            dosageUnitLabel.text = med?.dosageUnit.units(med?.dosage)
        }
    }
    
}
