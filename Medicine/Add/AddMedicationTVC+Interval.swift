//
//  AddMedicationTVC+Interval.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-01.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class AddMedicationTVC_Interval: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    var med: Medicine!
    var editMode: Bool = false
    
    
    // MARK: - Outlets
    
    @IBOutlet var intervalUnitLabel: UILabel!
    @IBOutlet var intervalUnitPicker: UIPickerView!
    @IBOutlet var intervalLabel: UILabel!
    @IBOutlet var intervalPicker: UIPickerView!
    @IBOutlet var alarmLabel: UILabel!
    @IBOutlet var alarmPicker: UIDatePicker!
    
    
    // MARK: - Helper variables
    
    fileprivate var selectedRow = Rows.intervalUnitLabel
    fileprivate var minutes = ["0","15","30","45"]
    let cal = Calendar.current
    let dateFormatter = DateFormatter()
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Modify VC
        self.view.tintColor = UIColor.medRed
        
        if #available(iOS 13.0, macCatalyst 13.0, *) {
            self.navigationController?.isModalInPresentation = true
        }
        
        // Setup date formatter
        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.dateStyle = DateFormatter.Style.none
        
        if editMode == true {
            selectedRow = Rows.intervalLabel
        }
        
        // Set interval unit
        intervalUnitLabel.text = med.intervalUnit.description
        intervalUnitPicker.selectRow(Int(med.intervalUnit.rawValue), inComponent: 0, animated: false)
        
        // Set interval
        if (med.intervalUnit == Intervals.hourly) {
            let hr = Int(med.interval)
            let min = String(Int(60 * (med.interval.truncatingRemainder(dividingBy: 1))))
            
            intervalPicker.selectRow(hr, inComponent: 0, animated: false)
            
            if let minIndex = minutes.firstIndex(of: min) {
                intervalPicker.selectRow(minIndex, inComponent: 2, animated: false)
            } else {
                intervalPicker.selectRow(0, inComponent: 2, animated: false)
            }
        } else {
            intervalPicker.selectRow(Int(med.interval) - 1, inComponent: 0, animated: false)
        }
        
        updateIntervalLabel()
        
        // Set alarm
        if let alarm = med.intervalAlarm {
            let components = (cal as NSCalendar).components([NSCalendar.Unit.hour, NSCalendar.Unit.minute], from: alarm as Date)
            alarmPicker.date = (cal as NSCalendar).date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: Date(), options: [])!
        } else {
            if let date = (cal as NSCalendar).date(bySettingUnit: NSCalendar.Unit.minute, value: 0, of: Date(), options: []) {
                med.intervalAlarm = date
                alarmPicker.date = date
            }
        }
        
        updateAlertLabel()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
        let row = Rows(index: indexPath)
        
        switch(row) {
        case Rows.intervalUnitPicker:
            if selectedRow == Rows.intervalUnitLabel {
                return 175
            }
        case Rows.intervalPicker:
            if selectedRow == Rows.intervalLabel {
                return 175
            }
        case Rows.alarmLabel:
            if med.intervalUnit == Intervals.daily {
                return UITableView.automaticDimension
            }
        case Rows.alarmPicker:
            if selectedRow == Rows.alarmLabel {
                return 216
            }
        default:
            return UITableView.automaticDimension
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
            if #available(iOS 13.0, macCatalyst 13.0, *) {
                cell.detailTextLabel?.textColor = UIColor.secondaryLabel
            } else {
                cell.detailTextLabel?.textColor = UIColor.gray
            }
        }
        
        switch(row) {
        case Rows.intervalLabel:
            if row != selectedRow {
                cell.preservesSuperviewLayoutMargins = false
                cell.layoutMargins = UIEdgeInsets.zero
                cell.separatorInset = UIEdgeInsets.zero
                cell.contentView.layoutMargins = UIEdgeInsets.init(top: 0, left: tableView.separatorInset.left, bottom: 0, right: tableView.separatorInset.left)
            }
        case Rows.alarmLabel:
            if row != selectedRow {
                cell.preservesSuperviewLayoutMargins = false
                cell.layoutMargins = UIEdgeInsets.zero
                cell.separatorInset = UIEdgeInsets.zero
                cell.contentView.layoutMargins = UIEdgeInsets.init(top: 0, left: tableView.separatorInset.left, bottom: 0, right: tableView.separatorInset.left)
            }
        default: break
        }
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let newSelect = Rows(index: indexPath)
        
        if selectedRow == newSelect {
            selectedRow = Rows.none
        } else {
            selectedRow = newSelect
        }
        
        // Reload labels
        let labels = [Rows.intervalLabel.index(), Rows.intervalUnitLabel.index(), Rows.alarmLabel.index()]
        tableView.reloadRows(at: labels, with: .none)
        
        // Reload table
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    // MARK: - Picker data source
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if (pickerView == intervalUnitPicker) {
            return 1
        }
        
        if (pickerView == intervalPicker) {
            if (med.intervalUnit == Intervals.hourly) {
                return 4
            } else {
                return 2
            }
        }
        
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (pickerView == intervalUnitPicker) {
            return Intervals.count
        }
        
        if (pickerView == intervalPicker) {
            if (med.intervalUnit == Intervals.hourly) {
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
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if (pickerView == intervalUnitPicker) {
            return 120.0
        }
        
        if (pickerView == intervalPicker) {
            if (med.intervalUnit == Intervals.hourly) {
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
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30.0
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if (pickerView == intervalUnitPicker) {
            if let unit = Intervals(rawValue: Int16(row))?.description {
                return NSAttributedString(string: unit)
            }
        }
        
        if (pickerView == intervalPicker) {
            if (med.intervalUnit == Intervals.hourly) {
                switch(component) {
                case 0:
                    return NSAttributedString(string: "\(row)")
                case 1:
                    let unit = med.intervalUnit.units(med.interval)
                    let label = NSMutableAttributedString(string: unit)
                    label.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.medGray1, range: NSMakeRange(0, label.length))
                    return label
                case 2:
                    return NSAttributedString(string: minutes[row % 4])
                case 3:
                    let label = NSMutableAttributedString(string: "min")
                    label.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.medGray1, range: NSMakeRange(0, label.length))
                    return label
                default:
                    return nil
                }
            } else {
                switch(component) {
                case 0:
                    return NSAttributedString(string: "\(row+1)")
                default:
                    let unit = med.intervalUnit.units(med.interval)
                    let label = NSMutableAttributedString(string: unit)
                    label.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.medGray1, range: NSMakeRange(0, label.length))
                    return label
                }
            }
        }
        
        return nil
    }
    
    
    // MARK: - Picker delegate
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (pickerView == intervalUnitPicker) {
            if let unit = Intervals(rawValue: Int16(row)) {
                med.intervalUnit = unit
                med.interval = 1.0
                
                intervalUnitLabel.text = unit.description
                updateIntervalLabel()
            
                switch(med.intervalUnit) {
                case .hourly:
                    intervalPicker.selectRow(1, inComponent: 0, animated: false)
                    med.intervalAlarm = nil
                case .daily:
                    intervalPicker.selectRow(0, inComponent: 0, animated: false)
                    med.intervalAlarm = alarmPicker.date
                default: break
                }
                
                // Reload interval picker to account for changed units
                intervalPicker.reloadAllComponents()
            }
        }
        
        if (pickerView == intervalPicker) {
            if (med.intervalUnit == Intervals.hourly) {
                // Prevent selection of 0 hours and minutes
                if (row == 0 && component == 0 && pickerView.selectedRow(inComponent: 2) == 0) {
                    pickerView.selectRow(1, inComponent: 2, animated: true)
                } else if (row == 0 && component == 2 && pickerView.selectedRow(inComponent: 0) == 0) {
                    pickerView.selectRow(1, inComponent: 0, animated: true)
                }
                
                let hr = Float(pickerView.selectedRow(inComponent: 0))
                let min = (minutes[pickerView.selectedRow(inComponent: 2)] as NSString).floatValue / 60
                med.interval = hr + min
            } else {
                med.interval = Float(row) + 1
            }
            
            updateIntervalLabel()
            
            // Reload interval picker to account for changed units
            intervalPicker.reloadAllComponents()
        }
        
        // Reload table view
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    // MARK: - Update interval values
    
    func updateIntervalLabel() {
        let hr = Int(med.interval)
        let min = Int(60 * (med.interval.truncatingRemainder(dividingBy: 1)))
        let hrUnit = med.intervalUnit.units(med.interval)
        
        if (hr == 1 && min == 0) {
            intervalLabel.text = String(format:"%@", hrUnit.capitalized)
        } else if (min == 0) {
            intervalLabel.text = String(format:"%d %@", hr, hrUnit)
        } else if (hr == 0) {
            intervalLabel.text = String(format:"%d min", min)
        } else {
            intervalLabel.text = String(format:"%d %@ %d min", hr, hrUnit, min)
        }
    }
    
    @IBAction func updateAlert(_ sender: UIDatePicker) {
        let components = (cal as NSCalendar).components([NSCalendar.Unit.hour, NSCalendar.Unit.minute], from: sender.date)
        var date = (cal as NSCalendar).date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: Date(), options: [])!
        
        while date.compare(Date()) == .orderedAscending {
            date = (cal as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: 1, to: date, options: [])!
        }
        
        med.intervalAlarm = date
        
        updateAlertLabel()
    }
    
    func updateAlertLabel() {
        if let date = med.intervalAlarm {
            if date.isMidnight() {
                alarmLabel.text = "Midnight"
            } else {
                alarmLabel.text = dateFormatter.string(from: date as Date)
            }
        } else {
            alarmLabel.text = "None"
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
    
    init(index: IndexPath) {
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
    
    func index() -> IndexPath {
        switch self {
        case .intervalUnitLabel:
            return IndexPath(row: 0, section: 0)
        case .intervalUnitPicker:
            return IndexPath(row: 1, section: 0)
        case .intervalLabel:
            return IndexPath(row: 2, section: 0)
        case .intervalPicker:
            return IndexPath(row: 3, section: 0)
        case .alarmLabel:
            return IndexPath(row: 0, section: 1)
        case .alarmPicker:
            return IndexPath(row: 1, section: 1)
        default:
            return IndexPath(row: 0, section: 0)
        }
    }
}
