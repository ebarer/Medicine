//
//  HistoryAddVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-29.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class HistoryAddVC: UIViewController {

    var date = NSDate()
    let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    @IBOutlet var picker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set picker min/max values
        picker.minimumDate = cal.dateByAddingUnit(NSCalendarUnit.Day, value: -6, toDate: cal.startOfDayForDate(NSDate()), options: [])
        picker.maximumDate = NSDate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func updateDate(sender: UIDatePicker) {
        date = sender.date
    }
    
}