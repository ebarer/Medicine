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
    
    @IBOutlet var intervalUnitPicker: UIPickerView!
    
    
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
            return 3
        }
        
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (pickerView == intervalUnitPicker) {
            switch(component) {
            case 0:
                return 20
            case 1:
                return 10
            case 2:
                return 3
            default:
                return 1
            }
        }
        
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if (pickerView == intervalUnitPicker) {
            switch(component) {
            case 0:
                return String(row)
            case 1:
                return String(row)
            case 2:
                return Doses(rawValue: Int16(row))?.description
            default:
                return nil
            }
        }
        
        return nil
    }
    
    
    // MARK: - Update interval values
    
    @IBAction func updateIntervalUnit(sender: UITextField) {

    }
    
    @IBAction func updateInterval(sender: UITextField) {

    }

}
