//
//  AddMedicationTVC+Interval.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-01.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class AddMedicationTVC_Interval: UITableViewController, UIPickerViewDelegate {

    weak var med: Medicine?
    
    
    // MARK: - Outlets
    
    @IBOutlet var intervalUnitLabel: UILabel!
    @IBOutlet var intervalUnitPicker: UIPickerView!
    @IBOutlet var intervalLabel: UILabel!
    @IBOutlet var intervalPicker: UIPickerView!
    
    
    // MARK: - Helper variables
    
    private var minutes = ["0","15","30","45"]
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Modify VC
        self.view.tintColor = UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0)
        
        // Set values
        if let medicine = med {
            intervalUnitLabel.text = medicine.intervalUnit.description
            updateIntervalLabel()
            
            intervalUnitPicker.selectRow(Int(medicine.intervalUnit.rawValue), inComponent: 0, animated: false)
            
            if (med?.intervalUnit == Intervals.Hourly) {
                let hr = Int(medicine.interval)
                let min = String(Int(60 * (medicine.interval % 1)))
                
                intervalPicker.selectRow(hr, inComponent: 0, animated: false)
                
                if let minIndex = minutes.indexOf(min) {
                    intervalPicker.selectRow(minIndex, inComponent: 2, animated: false)
                } else {
                    intervalPicker.selectRow(0, inComponent: 2, animated: false)
                }
            } else {
                intervalPicker.selectRow(Int(medicine.interval) - 1, inComponent: 0, animated: false)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Picker delegate/data source
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        if (pickerView == intervalUnitPicker) {
            return 1
        }
        
        if (pickerView == intervalPicker) {
            if (med?.intervalUnit == Intervals.Hourly) {
                return 4
            } else {
                return 2
            }
        }
        
        return 0
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (pickerView == intervalUnitPicker) {
            return Intervals.count
        }
        
        if (pickerView == intervalPicker) {
            if (med?.intervalUnit == Intervals.Hourly) {
                switch(component) {
                case 0:
                    return 24
                case 2:
                    return 999
                default:
                    return 1
                }
            } else {
                switch(component) {
                case 0:
                    return 999
                default:
                    return 1
                }
            }
        }
        
        return 0
    }
    
    func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if (pickerView == intervalUnitPicker) {
            return 120.0
        }
        
        if (pickerView == intervalPicker) {
            if (med?.intervalUnit == Intervals.Hourly) {
                switch(component) {
                case 1:
                    return 80.0
                case 3:
                    return 50.0
                default:
                    return 40.0
                }
            } else {
                switch(component) {
                case 0:
                    return 60.0
                default:
                    return 80.0
                }
            }
        }
        
        return 0.0
    }
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if (pickerView == intervalUnitPicker) {
            if let unit = Intervals(rawValue: Int16(row))?.description {
                return NSAttributedString(string: unit)
            }
        }
        
        if (pickerView == intervalPicker) {
            if (med?.intervalUnit == Intervals.Hourly) {
                switch(component) {
                case 0:
                    return NSAttributedString(string: "\(row)")
                case 1:
                    let label = NSMutableAttributedString(string: "hours")
                    label.addAttribute(NSForegroundColorAttributeName, value: UIColor.lightGrayColor(), range: NSMakeRange(0, label.length))
                    
                    return label
                case 2:
                    return NSAttributedString(string: minutes[row % 4])
                case 3:
                    let label = NSMutableAttributedString(string: "min")
                    label.addAttribute(NSForegroundColorAttributeName, value: UIColor.lightGrayColor(), range: NSMakeRange(0, label.length))
                    return label
                default:
                    return nil
                }
            } else {
                switch(component) {
                case 0:
                    return NSAttributedString(string: "\(row+1)")
                default:
                    if let unit = med?.intervalUnit.units(med?.interval) {
                        let label = NSMutableAttributedString(string: unit)
                        label.addAttribute(NSForegroundColorAttributeName, value: UIColor.lightGrayColor(), range: NSMakeRange(0, label.length))
                        return label
                    }
                }
            }
        }
        
        return nil
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (pickerView == intervalUnitPicker) {
            if let unit = Intervals(rawValue: Int16(row)) {
                med?.intervalUnit = unit
                med?.interval = 1.0
                
                intervalUnitLabel.text = unit.description
                updateIntervalLabel()
                
                if (med?.intervalUnit == .Hourly) {
                    intervalPicker.selectRow(1, inComponent: 0, animated: false)
                } else {
                    intervalPicker.selectRow(0, inComponent: 0, animated: false)
                }
                
                intervalPicker.reloadAllComponents()
            }
        }
        
        if (pickerView == intervalPicker) {
            if (med?.intervalUnit == Intervals.Hourly) {
                // Prevent selection of 0 hours and minutes
                if (row == 0 && component == 0 && pickerView.selectedRowInComponent(2) == 0) {
                    pickerView.selectRow(1, inComponent: 2, animated: true)
                } else if (row == 0 && component == 2 && pickerView.selectedRowInComponent(0) == 0) {
                    pickerView.selectRow(1, inComponent: 0, animated: true)
                }
                
                let hr = Float(pickerView.selectedRowInComponent(0))
                let min = (minutes[pickerView.selectedRowInComponent(2)] as NSString).floatValue / 60
                med?.interval = hr + min
            } else {
                med?.interval = Float(row) + 1
            }
            
            updateIntervalLabel()
        }
    }
    
    
    // MARK: - Update interval values
    
    func updateIntervalLabel() {
        if let medicine = med {
            let hr = Int(medicine.interval)
            let min = Int(60 * (medicine.interval % 1))
            let hrUnit = medicine.intervalUnit.units(medicine.interval)
            
            if (hr == 1 && min == 0) {
                intervalLabel.text = String(format:"%@", hrUnit.capitalizedString)
            } else if (min == 0) {
                intervalLabel.text = String(format:"%d %@", hr, hrUnit)
            } else if (hr == 0) {
                intervalLabel.text = String(format:"%d min", min)
            } else {
                intervalLabel.text = String(format:"%d %@ %d min", hr, hrUnit, min)
            }
        }
    }

}
