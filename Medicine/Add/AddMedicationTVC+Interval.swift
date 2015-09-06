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
    @IBOutlet var alarmLabel: UILabel!
    @IBOutlet var alarmPicker: UIDatePicker!
    
    
    // MARK: - Helper variables
    
    private var selectedRow = Rows.intervalUnitLabel
    private var minutes = ["0","15","30","45"]
    let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    let dateFormatter = NSDateFormatter()
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Modify VC
        self.view.tintColor = UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0)
        
        // Setup date formatter
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
        
        // Set values
        if let medicine = med {
            // Set interval unit
            intervalUnitLabel.text = medicine.intervalUnit.description
            intervalUnitPicker.selectRow(Int(medicine.intervalUnit.rawValue), inComponent: 0, animated: false)
            
            // Set interval
            updateIntervalLabel()
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
            
            if let alarm = medicine.intervalAlarm {
                if alarm.isMidnight() {
                    alarmLabel.text = "Midnight"
                } else {
                    alarmLabel.text = dateFormatter.stringFromDate(alarm)
                }

                alarmPicker.date = alarm
            } else {
                if let date = cal.dateBySettingUnit(NSCalendarUnit.Minute, value: 0, ofDate: NSDate(), options: []) {
                    alarmPicker.date = date
                    alarmLabel.text = dateFormatter.stringFromDate(date)
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = Rows(index: indexPath)
        
        switch(row) {
        case Rows.intervalUnitPicker:
            if selectedRow == Rows.intervalUnitLabel {
                return 162
            }
        case Rows.intervalPicker:
            if selectedRow == Rows.intervalLabel {
                return 162
            }
        case Rows.alarmLabel:
            if med?.intervalUnit == Intervals.Daily {
                return tableView.rowHeight
            }
        case Rows.alarmPicker:
            if selectedRow == Rows.alarmLabel {
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
            cell.detailTextLabel?.textColor = UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0)
        } else {
            cell.detailTextLabel?.textColor = UIColor.grayColor()
        }
        
        switch(row) {
        case Rows.intervalLabel:
            if row != selectedRow {
                cell.separatorInset = UIEdgeInsetsZero
            }
        case Rows.alarmLabel:
            if row != selectedRow {
                cell.separatorInset = UIEdgeInsetsZero
            }
        default: break
        }
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedRow = Rows(index: indexPath)
        
        // Reload labels
        let labels = [Rows.intervalLabel.index(), Rows.intervalUnitLabel.index(), Rows.alarmLabel.index()]
        tableView.reloadRowsAtIndexPaths(labels, withRowAnimation: .None)
        
        // Reload table
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    // MARK: - Picker data source
    
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
                    return 4
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
    
    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30.0
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
                    if let unit = med?.intervalUnit.units(med?.interval) {
                        let label = NSMutableAttributedString(string: unit)
                        label.addAttribute(NSForegroundColorAttributeName, value: UIColor.lightGrayColor(), range: NSMakeRange(0, label.length))
                        return label
                    }
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
    
    
    // MARK: - Picker delegate
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let medicine = med {
            if (pickerView == intervalUnitPicker) {
                if let unit = Intervals(rawValue: Int16(row)) {
                    medicine.intervalUnit = unit
                    medicine.interval = 1.0
                    
                    intervalUnitLabel.text = unit.description
                    updateIntervalLabel()
                
                    switch(medicine.intervalUnit) {
                    case .Hourly:
                        intervalPicker.selectRow(1, inComponent: 0, animated: false)
                        medicine.intervalAlarm = nil
                    case .Daily:
                        intervalPicker.selectRow(0, inComponent: 0, animated: false)
                        medicine.intervalAlarm = alarmPicker.date
                    default: break
                    }
                    
                    // Reload interval picker to account for changed units
                    intervalPicker.reloadAllComponents()
                }
            }
            
            if (pickerView == intervalPicker) {
                if (medicine.intervalUnit == Intervals.Hourly) {
                    // Prevent selection of 0 hours and minutes
                    if (row == 0 && component == 0 && pickerView.selectedRowInComponent(2) == 0) {
                        pickerView.selectRow(1, inComponent: 2, animated: true)
                    } else if (row == 0 && component == 2 && pickerView.selectedRowInComponent(0) == 0) {
                        pickerView.selectRow(1, inComponent: 0, animated: true)
                    }
                    
                    let hr = Float(pickerView.selectedRowInComponent(0))
                    let min = (minutes[pickerView.selectedRowInComponent(2)] as NSString).floatValue / 60
                    medicine.interval = hr + min
                } else {
                    medicine.interval = Float(row) + 1
                }
                
                updateIntervalLabel()
                
                // Reload interval picker to account for changed units
                intervalPicker.reloadAllComponents()
            }
            
            // Reload table view
            tableView.beginUpdates()
            tableView.endUpdates()
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
    
    @IBAction func updateAlert(sender: UIDatePicker) {
        if let medicine = med {
            medicine.intervalAlarm = sender.date
            
            if sender.date.isMidnight() {
                alarmLabel.text = "Midnight"
            } else {
                alarmLabel.text = dateFormatter.stringFromDate(sender.date)
            }
        }
    }

}

private enum Rows: Int {
    case none = -1
    case intervalUnitLabel
    case intervalUnitPicker
    case intervalLabel
    case intervalPicker
    case alarmLabel
    case alarmPicker
    
    init(index: NSIndexPath) {
        var row = Rows.none
        
        switch (index.section, index.row) {
        case (0, 0):
            row = Rows.intervalUnitLabel
        case (0, 1):
            row = Rows.intervalUnitPicker
        case (0, 2):
            row = Rows.intervalLabel
        case (0, 3):
            row = Rows.intervalPicker
        case (1, 0):
            row = Rows.alarmLabel
        case (1, 1):
            row = Rows.alarmPicker
        default:
            row = Rows.none
        }

        self = row
    }
    
    func index() -> NSIndexPath {
        switch self {
        case .intervalUnitLabel:
            return NSIndexPath(forRow: 0, inSection: 0)
        case .intervalUnitPicker:
            return NSIndexPath(forRow: 1, inSection: 0)
        case .intervalLabel:
            return NSIndexPath(forRow: 2, inSection: 0)
        case .intervalPicker:
            return NSIndexPath(forRow: 3, inSection: 0)
        case .alarmLabel:
            return NSIndexPath(forRow: 0, inSection: 1)
        case .alarmPicker:
            return NSIndexPath(forRow: 1, inSection: 1)
        default:
            return NSIndexPath(forRow: 0, inSection: 0)
        }
    }
}
