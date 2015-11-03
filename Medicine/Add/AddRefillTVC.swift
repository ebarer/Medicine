//
//  AddRefillTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-31.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class AddRefillTVC: UITableViewController {
    
    var med:Medicine?
    
    var date = NSDate()
    let cal = NSCalendar.currentCalendar()
    let dateFormatter = NSDateFormatter()
    
    
    // MARK: - Outlets

    @IBOutlet var quantityInput: UITextField!
    @IBOutlet var quantityUnitLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var picker: UIDatePicker!
    
    
    // MARK: - Helper variables
    
    private var selectedRow = Rows.none
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        
        // Modify VC
        self.view.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        
        // Setup date formatter
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
        
        // Set picker min/max values
        picker.maximumDate = NSDate()
    }
    
    override func viewWillAppear(animated: Bool) {
        // Set values
        if let history = med?.refillHistory?.array as? [Prescription] {
            if let quantity = history.last?.quantity {
                quantityInput.text = String(format:"%g", quantity)
                quantityUnitLabel.text = med?.dosageUnit.description
            }
        }
        
        dateLabel.text = dateFormatter.stringFromDate(date)
    }
    
    override func viewDidAppear(animated: Bool) {
        quantityInput.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        quantityInput.resignFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = Rows(index: indexPath)
        
        switch(row) {
        case Rows.datePicker:
            if selectedRow == Rows.dateLabel {
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
        case Rows.dateLabel:
            if row != selectedRow {
                cell.separatorInset = UIEdgeInsetsZero
            }
        default: break
        }
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let newSelect = Rows(index: indexPath)
        
        if selectedRow == newSelect {
            selectedRow = Rows.none
        } else {
            selectedRow = newSelect
        }
        
        // Reload labels
        let labels = [Rows.quantityAmount.index(), Rows.quantityUnit.index(), Rows.dateLabel.index()]
        tableView.reloadRowsAtIndexPaths(labels, withRowAnimation: .None)
        
        // Reload table
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    // MARK: - Actions
    
    @IBAction func updateDate(sender: UIDatePicker) {
        date = sender.date
            
        if sender.date.isMidnight() {
            dateLabel.text = "Midnight"
        } else {
            dateLabel.text = dateFormatter.stringFromDate(sender.date)
        }
    }
    
    
    // MARK: - Navigation
    
    @IBAction func saveRefill(sender: AnyObject) {
//        med.addRefill(self.moc, date: NSDate(), refillQuantity: 5)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func dismissView(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}



private enum Rows: Int {
    case none = -1
    case quantityAmount
    case quantityUnit
    case dateLabel
    case datePicker
    
    init(index: NSIndexPath) {
        var row = Rows.none
        
        switch (index.section, index.row) {
        case (0, 0):
            row = Rows.quantityAmount
        case (0, 1):
            row = Rows.quantityUnit
        case (1, 0):
            row = Rows.dateLabel
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
        case .dateLabel:
            return NSIndexPath(forRow: 0, inSection: 1)
        case .datePicker:
            return NSIndexPath(forRow: 1, inSection: 1)
        default:
            return NSIndexPath(forRow: 0, inSection: 0)
        }
    }
}
