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
    @IBOutlet var intervalLabel: UIView!
    @IBOutlet var intervalPicker: UIPickerView!
    @IBOutlet var intervalPickerHours: UIDatePicker!
    
    
    // MARK: - Helper variables
    
    private var minutes = ["0","15","30","45"]
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.tintColor = UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0)
        
        if let name = med?.name {
            self.navigationItem.backBarButtonItem?.title = name
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
                    return NSAttributedString(string: "hours")
                case 2:
                    return NSAttributedString(string: minutes[row % 4])
                case 3:
                    return NSAttributedString(string: "min")
                default:
                    return nil
                }
            } else {
                switch(component) {
                case 0:
                    return NSAttributedString(string: "\(row+1)")
                default:
                    if let unit = med?.intervalUnit.units(med?.interval) {
                        return NSAttributedString(string: unit)
                    }
                }
            }
        }
        
        return nil
    }
    
    
    // MARK: - Update interval values
    
    @IBAction func updateIntervalUnit(sender: UITextField) {

    }
    
    @IBAction func updateInterval(sender: UITextField) {

    }

    @IBAction func updateIntervalHours(sender: UIDatePicker) {
        print(sender.date)
    }
    
}
