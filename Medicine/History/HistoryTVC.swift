//
//  HistoryTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-28.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class HistoryTVC: UITableViewController {

    let emptyDates = false
    var dates = [Date]()
    var history = [Date: [Dose]]()
    
    
    // MARK: - Helper variables
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var moc: NSManagedObjectContext!
    
    let cal = Calendar.current
    let dateFormatter = DateFormatter()
    
    var editButtons = [UIBarButtonItem]()
    
    
    // MARK: - Initialization
    
    required init?(coder aDecoder: NSCoder) {
        // Setup context
        moc = appDelegate.managedObjectContext
        super.init(coder: aDecoder)
    }
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Modify VC
        self.view.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        self.navigationController?.toolbar.isTranslucent = true
        self.navigationController?.toolbar.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        // Configure toolbar buttons
        let deleteButton = UIBarButtonItem(title: "Delete", style: UIBarButtonItemStyle.plain, target: self, action: #selector(deleteDoses))
        deleteButton.isEnabled = false
        editButtons.append(deleteButton)
        setToolbarItems(editButtons, animated: true)
        
        // Add observeres for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(refreshView), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func refreshView() {
        loadHistory()
        displayEmptyView()
    }
    
    func loadHistory() {
        // Clear history
        history.removeAll()

        var historyArray = [Dose]()
        for med in medication {
            if let temp = med.doseHistory?.array as? [Dose] {
                historyArray += temp
            }
        }
        
        // Sort history array
        historyArray.sort(by: { $0.date.compare($1.date as Date) == .orderedDescending })
        
        // Get dates in history
        if emptyDates == true {
            // Get all dates from today to last dose, including empty dates
            var date = Date()
            while date.compare(historyArray.last!.date as Date) != .orderedAscending {
                dates.append(date)
                date = (cal as NSCalendar).date(byAdding: .day, value: -1, to: date, options: [])!
            }
        } else {
            // Get dates as exclusive elements from first dose to last
            var temp = Set<Date>()
            for dose in historyArray {
                temp.insert(cal.startOfDay(for: dose.date as Date))
            }
            
            // Store dates in array
            dates = temp.sorted(by: { $0.compare($1) == .orderedDescending })
        }
        
        // Store doses in history dictionary, with dates as keys
        for date in dates {
            let doses = historyArray.filter({cal.isDate($0.date as Date, inSameDayAs: date)})
            history.updateValue(doses, forKey: date)
        }
    }

    func displayEmptyView() {
        if medication.count == 0 {
            navigationItem.leftBarButtonItem?.isEnabled = false
            navigationItem.rightBarButtonItem?.isEnabled = false
            
            if let emptyView = UINib(nibName: "MainEmptyView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView {
                tableView.backgroundView = emptyView
            }
        } else if history.count == 0 {
            navigationItem.leftBarButtonItem?.isEnabled = false
            navigationItem.rightBarButtonItem?.isEnabled = true
            
            // Create empty message
            if let emptyView = UINib(nibName: "HistoryEmptyView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView {
                tableView.backgroundView = emptyView
            }
        } else {
            navigationItem.leftBarButtonItem?.isEnabled = true
            navigationItem.leftBarButtonItem?.isEnabled = true
            tableView.backgroundView = nil
        }
        
        tableView.reloadData()
    }
    
    
    // MARK: - Table headers
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return dates.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionDate = dates[section]
        
        if cal.isDateInToday(sectionDate) {
            dateFormatter.timeStyle = DateFormatter.Style.none
            dateFormatter.dateStyle = DateFormatter.Style.medium
            return "Today  \(dateFormatter.string(from: sectionDate))"
        } else if cal.isDateInYesterday(sectionDate) {
            dateFormatter.timeStyle = DateFormatter.Style.none
            dateFormatter.dateStyle = DateFormatter.Style.medium
            return "Yesterday  \(dateFormatter.string(from: sectionDate))"
        } else if sectionDate.isDateInLastWeek() {
            dateFormatter.dateFormat = "EEEE  MMM d, YYYY"
            return dateFormatter.string(from: sectionDate)
        } else {
            dateFormatter.dateFormat = "EEEE  MMM d, YYYY"
            return dateFormatter.string(from: sectionDate)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let sectionDate = dates[section]
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView

//        header.contentView.backgroundColor = UIColor.groupTableViewBackgroundColor()
//
//        // Add top seperator
//        let topSeperator = UIView(frame: CGRectMake(0, 0, header.frame.width, 0.5))
//        topSeperator.backgroundColor = UIColor(white: 0.67, alpha: 1.0)
//        header.addSubview(topSeperator)
//        
//        // Add bottom seperator
//        let bottomSeperator = UIView(frame: CGRectMake(0, header.frame.height-0.5, header.frame.width, 0.5))
//        bottomSeperator.backgroundColor = UIColor(white: 0.67, alpha: 1.0)
//        header.addSubview(bottomSeperator)

        // Set header title
        header.textLabel?.text = header.textLabel?.text?.uppercased()
        header.textLabel?.textColor = UIColor(white: 0.43, alpha: 1.0)
        
        if let text = header.textLabel?.text {
            let string = NSMutableAttributedString(string: text)
            string.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 13.0), range: NSMakeRange(0, string.length))
            
            if cal.isDateInToday(sectionDate) {
                string.addAttribute(NSForegroundColorAttributeName, value: UIColor.red, range: NSMakeRange(0, string.length))
            }
            
            if let index = text.characters.index(of: " ") {
                let pos = text.characters.distance(from: text.startIndex, to: index)
                string.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 13.0, weight: UIFontWeightSemibold), range: NSMakeRange(0, pos))
            }
            
            header.textLabel?.attributedText = string
        }
    }

    
    // MARK: - Table rows
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionDate = dates[section]
        
        if let count = history[sectionDate]?.count {
            return (count == 0) ? 1 : count
        }
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionDate = dates[indexPath.section]
        
        if let count = history[sectionDate]?.count {
            return (count > 0) ? 55.0 : tableView.rowHeight
        }
        
        return tableView.rowHeight
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath)
        let sectionDate = dates[indexPath.section]
        if let date = history[sectionDate] {
            if date.count > indexPath.row {
                let dose = date[indexPath.row]
                if let med = dose.medicine {
                    // Setup date formatter
                    dateFormatter.timeStyle = DateFormatter.Style.short
                    dateFormatter.dateStyle = DateFormatter.Style.none
                    
                    // Specify selection color
                    cell.selectedBackgroundView = UIView()
                    
                    if dose.dosage > 0 {
                        cell.textLabel?.textColor = UIColor.black
                        cell.textLabel?.text = "\(dateFormatter.string(from: dose.date as Date))"
                        cell.detailTextLabel?.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
                        cell.detailTextLabel?.text = String(format:"%@ - %g %@", med.name!, dose.dosage, dose.dosageUnit.units(dose.dosage))
                    } else {
                        cell.textLabel?.textColor = UIColor.lightGray
                        cell.textLabel?.text = "Skipped (\(dateFormatter.string(from: dose.date as Date)))"
                        cell.detailTextLabel?.textColor = UIColor.lightGray
                        cell.detailTextLabel?.text = String(format:"%@", med.name!)
                    }
                }
            } else {
                cell.textLabel?.textColor = UIColor.lightGray
                cell.textLabel?.text = "No doses logged"
                cell.detailTextLabel?.text?.removeAll()
            }
        }
        
        return cell
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let sectionDate = dates[indexPath.section]
        return history[sectionDate]?.count != 0
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let sectionDate = dates[indexPath.section]
        return history[sectionDate]?.count != 0
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableViewScrollPosition.none)
        deleteDoses()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        updateDeleteButtonLabel()
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        updateDeleteButtonLabel()
    }
    
    
    // MARK: - Toolbar methods
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        if editing == true {
            self.navigationController?.setToolbarHidden(false, animated: true)
        } else {
            self.navigationController?.setToolbarHidden(true, animated: true)
            updateDeleteButtonLabel()
        }
    }
    
    func updateDeleteButtonLabel() {
        if let selectedRows = tableView.indexPathsForSelectedRows {
            editButtons[0].title = "Delete (\(selectedRows.count))"
            editButtons[0].isEnabled = true
        } else {
            editButtons[0].title = "Delete"
            editButtons[0].isEnabled = false
        }
    }
    
    func addDose() {
        performSegue(withIdentifier: "addDose", sender: self)
    }
    
    func deleteDoses() {
        if let selectedRowIndexes = tableView.indexPathsForSelectedRows {
            for indexPath in selectedRowIndexes.reversed() {
                let sectionDate = dates[indexPath.section]
                if let dose = history[sectionDate]?[indexPath.row] {
                    if let med = dose.medicine {
                        history[sectionDate]?.removeObject(dose)
                        
                        if med.lastDose == dose {
                            _ = med.untakeLastDose(moc)
                        } else {
                            med.untakeDose(dose, moc: moc)
                        }
                        
                        if tableView.numberOfRows(inSection: indexPath.section) == 1 {
                            if emptyDates == true {
                                let label = tableView.cellForRow(at: indexPath)?.textLabel
                                let detail = tableView.cellForRow(at: indexPath)?.detailTextLabel
                                
                                label?.textColor = UIColor.lightGray
                                label?.text = "No doses logged"
                                detail?.text?.removeAll()
                            } else {
                                history.removeValue(forKey: sectionDate)
                                dates.removeObject(sectionDate)
                                tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
                            }
                        } else {
                            tableView.deleteRows(at: [indexPath], with: .automatic)
                        }
                    }
                }
            }
            
            if history.count == 0 {
                displayEmptyView()
            }
            
            updateDeleteButtonLabel()
            setEditing(false, animated: true)

            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
        }
    }
    
    
    // MARK: - Navigation methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addDose" {
            if let vc = segue.destination.childViewControllers[0] as? AddDoseTVC {
                vc.globalHistory = true
            }
        }
    }

}


// Protect against invalid arguments when deleting
extension Array {
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}
