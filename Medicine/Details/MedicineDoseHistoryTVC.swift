//
//  MedicineDoseHistoryTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-28.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class MedicineDoseHistoryTVC: UITableViewController {
    
    weak var med:Medicine!
    let emptyDates = false
    var dates = [NSDate]()
    var history = [Dose]()
    
    
    // MARK: - Helper variables
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext!
    
    let cal = NSCalendar.currentCalendar()
    let dateFormatter = NSDateFormatter()
    
    var normalButtons = [UIBarButtonItem]()
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
        self.title = "Dose History"
        self.view.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        self.navigationController?.toolbar.translucent = true
        self.navigationController?.toolbar.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        
        // Configure toolbar buttons
        let fixedButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let exportButton = UIBarButtonItem(title: "Export", style: UIBarButtonItemStyle.Plain, target: self, action: "exportDoses")
        let deleteButton = UIBarButtonItem(title: "Delete", style: UIBarButtonItemStyle.Plain, target: self, action: "deleteDoses")
        deleteButton.enabled = false
        
        normalButtons.append(exportButton)
        normalButtons.append(fixedButton)
        normalButtons.append(self.editButtonItem())
        
        editButtons.append(deleteButton)
        editButtons.append(fixedButton)
        editButtons.append(self.editButtonItem())

        setToolbarItems(normalButtons, animated: false)

        // Add observeres for notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTableAndNotifications", name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setToolbarHidden(false, animated: animated)
        
        loadHistory()
        displayEmptyView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func loadHistory() {
        // Clear history
        history.removeAll()
        
        // Store doses, sorted, in history array
        if let historySet = med.doseHistory {
            history += historySet.array as! [Dose]
        }
        
        // Sort history
        history.sortInPlace({ $0.date.compare($1.date) == .OrderedDescending })
        
        // Get dates
        if emptyDates == true {
            // Get all dates from today to last dose, including empty dates
            var date = NSDate()
            while date.compare(history.last!.date) != .OrderedAscending {
                dates.append(date)
                date = cal.dateByAddingUnit(.Day, value: -1, toDate: date, options: [])!
            }
        } else {
            // Get dates as exclusive elements from first dose to last
            var temp = Set<NSDate>()
            for dose in history {
                temp.insert(cal.startOfDayForDate(dose.date))
            }
            
            // Store dates in array
            dates = temp.sort({ $0.compare($1) == .OrderedDescending })
        }
    }
    
    func displayEmptyView() {
        if history.count == 0 {
            for button in self.normalButtons {
                button.enabled = false
            }
            
            // Create empty message
            if let emptyView = UINib(nibName: "HistoryEmptyView", bundle: nil).instantiateWithOwner(self, options: nil)[0] as? UIView {
                tableView.separatorStyle = UITableViewCellSeparatorStyle.None
                tableView.backgroundView = emptyView
            }
        } else {
            for button in self.normalButtons {
                button.enabled = true
            }
            
            tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            tableView.backgroundView = nil
        }
        
        tableView.reloadData()
    }

    
    // MARK: - Table headers
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return dates.count
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionDate = dates[section]

        if cal.isDateInToday(sectionDate) {
            dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
            dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
            return "Today  \(dateFormatter.stringFromDate(sectionDate))"
        } else if cal.isDateInYesterday(sectionDate) {
            dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
            dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
            return "Yesterday  \(dateFormatter.stringFromDate(sectionDate))"
        } else if sectionDate.isDateInLastWeek() {
            dateFormatter.dateFormat = "EEEE  MMM d, YYYY"
            return dateFormatter.stringFromDate(sectionDate)
        } else {
            dateFormatter.dateFormat = "EEEE  MMM d, YYYY"
            return dateFormatter.stringFromDate(sectionDate)
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let sectionDate = dates[section]
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        
        // Set header title
        header.textLabel?.text = header.textLabel?.text?.uppercaseString
        header.textLabel?.textColor = UIColor(white: 0.43, alpha: 1.0)
        
        if let text = header.textLabel?.text {
            let string = NSMutableAttributedString(string: text)
            string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(13.0), range: NSMakeRange(0, string.length))
            
            if cal.isDateInToday(sectionDate) {
                string.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: NSMakeRange(0, string.length))
            }
            
            if let index = text.characters.indexOf(" ") {
                let pos = text.startIndex.distanceTo(index)
                string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(13.0, weight: UIFontWeightSemibold), range: NSMakeRange(0, pos))
            }
            
            header.textLabel?.attributedText = string
        }
    }

    
    // MARK: - Table rows
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionDate = dates[section]
        let count = history.filter({cal.isDate($0.date, inSameDayAsDate: sectionDate)}).count
        return (count == 0) ? 1 : count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let sectionDate = dates[indexPath.section]
        let count = history.filter({cal.isDate($0.date, inSameDayAsDate: sectionDate)}).count
        return (count > 0) ? 55.0 : tableView.rowHeight
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {        
        let cell = tableView.dequeueReusableCellWithIdentifier("historyCell", forIndexPath: indexPath)
        let sectionDate = dates[indexPath.section]
        let date = history.filter({cal.isDate($0.date, inSameDayAsDate: sectionDate)})
        if date.count > indexPath.row {
            let dose = date[indexPath.row]
        
            // Setup date formatter
            dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
            dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
            
            // Specify selection color
            cell.selectedBackgroundView = UIView()

            // Setup cell
            cell.textLabel?.textColor = UIColor.blackColor()
            cell.textLabel?.text = "\(dateFormatter.stringFromDate(dose.date))"
            cell.detailTextLabel?.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
            cell.detailTextLabel?.text = String(format:"%g %@", dose.dosage, med.dosageUnit.units(dose.dosage))
        } else {
            cell.textLabel?.textColor = UIColor.lightGrayColor()
            cell.textLabel?.text = "No doses logged"
            cell.detailTextLabel?.text?.removeAll()
        }
        
        return cell
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let sectionDate = dates[indexPath.section]
        return history.filter({cal.isDate($0.date, inSameDayAsDate: sectionDate)}).count != 0
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let sectionDate = dates[indexPath.section]
        return history.filter({cal.isDate($0.date, inSameDayAsDate: sectionDate)}).count != 0
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
        deleteDoses()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        updateDeleteButtonLabel()
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        updateDeleteButtonLabel()
    }
    
    
    // MARK: - Toolbar methods
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing == true {
            setToolbarItems(editButtons, animated: true)
        } else {
            setToolbarItems(normalButtons, animated: true)
        }
    }
    
    func updateDeleteButtonLabel() {
        if let selectedRows = tableView.indexPathsForSelectedRows {
            editButtons[0].title = "Delete (\(selectedRows.count))"
            editButtons[0].enabled = true
        } else {
            editButtons[0].title = "Delete"
            editButtons[0].enabled = false
        }
    }
    
    @IBAction func addDose() {
        performSegueWithIdentifier("addDose", sender: self)
    }
    
    func deleteDoses() {
        if let selectedRowIndexes = tableView.indexPathsForSelectedRows {
            for indexPath in selectedRowIndexes.reverse() {
                let sectionDate = dates[indexPath.section]
                let dose = history.filter({cal.isDate($0.date, inSameDayAsDate: sectionDate)})[indexPath.row]
                
                history.removeObject(dose)
                
                if med.lastDose == dose {
                    med.untakeLastDose(moc)
                } else {
                    med.untakeDose(dose, moc: moc)
                }
                
                if tableView.numberOfRowsInSection(indexPath.section) == 1 {
                    if emptyDates == true {
                        let label = tableView.cellForRowAtIndexPath(indexPath)?.textLabel
                        let detail = tableView.cellForRowAtIndexPath(indexPath)?.detailTextLabel
                        
                        label?.textColor = UIColor.lightGrayColor()
                        label?.text = "No doses logged"
                        detail?.text?.removeAll()
                    } else {
                        dates.removeObject(sectionDate)
                        tableView.deleteSections(NSIndexSet(index: indexPath.section), withRowAnimation: .Automatic)
                    }
                } else {
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
            }

            if history.count == 0 {
                displayEmptyView()
            }
            
            updateDeleteButtonLabel()
            setEditing(false, animated: true)
            
            // Update widget
            NSNotificationCenter.defaultCenter().postNotificationName("refreshMedication", object: nil, userInfo: nil)
        }
    }
    
    func exportDoses() {
        // http://stackoverflow.com/questions/33349139/create-csv-file-in-swift-and-write-to-file
        print("Exporting...")
    }
    
    
    // MARK: - Navigation methods
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addDose" {
            if let vc = segue.destinationViewController.childViewControllers[0] as? AddDoseTVC {
                vc.med = med
            }
        }
    }
    
    
    // MARK: - Helper methods
    
    func refreshTableAndNotifications() {
        tableView.reloadData()
        
        // Clear old notifications
        let currentDate = NSDate()
        let notifications = UIApplication.sharedApplication().scheduledLocalNotifications!
        for notification in notifications {
            if let date = notification.fireDate {
                if date.compare(currentDate) == .OrderedAscending {
                    UIApplication.sharedApplication().cancelLocalNotification(notification)
                }
            }
        }
    }

}



// MARK: - Preview actions

//    @available(iOS 9.0, *)
//    override func previewActionItems() -> [UIPreviewActionItem] {
//        return previewActions
//    }
//
//    @available(iOS 9.0, *)
//    lazy var previewActions: [UIPreviewActionItem] = {
//        func previewActionForTitle(title: String, style: UIPreviewActionStyle = .Default) -> UIPreviewAction {
//            return UIPreviewAction(title: title, style: style) { previewAction, viewController in
//                guard let vc = viewController as? MedicineDetailsTVC else { return }
//                vc.performSegueWithIdentifier("addDose", sender: nil)
//                return
//            }
//        }
//
//        let action1 = previewActionForTitle("Take Dose")
//        return [action1]
//    }()
