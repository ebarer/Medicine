//
//  MedicineDoseHistoryTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-28.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData
import MessageUI

class MedicineDoseHistoryTVC: CoreDataTableViewController, MFMailComposeViewControllerDelegate {
    
    weak var med: Medicine!
    //let emptyDates = false
    //var dates = [Date]()
    //var history = [Date: [Dose]]()
    
    // MARK: - Helper variables
    let cdStack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    let cal = Calendar.current
    let dateFormatter = DateFormatter()
    
    var normalButtons = [UIBarButtonItem]()
    var editButtons = [UIBarButtonItem]()
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
        }
        
        // Modify VC
        self.title = "Dose History"
        self.view.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        self.navigationController?.toolbar.isTranslucent = true
        self.navigationController?.toolbar.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        
        // Configure toolbar buttons
        let fixedButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let exportButton = UIBarButtonItem(title: "Export", style: UIBarButtonItemStyle.plain, target: self, action: #selector(exportDoses))
        let deleteButton = UIBarButtonItem(title: "Delete", style: UIBarButtonItemStyle.plain, target: self, action: #selector(deleteDoses))
        deleteButton.isEnabled = false
        
        normalButtons.append(exportButton)
        normalButtons.append(fixedButton)
        normalButtons.append(self.editButtonItem)
        
        editButtons.append(deleteButton)
        editButtons.append(fixedButton)
        editButtons.append(self.editButtonItem)

        setToolbarItems(normalButtons, animated: false)

        // Add observeres for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(refreshView), name: NSNotification.Name(rawValue: "refreshView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshView), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        let request: NSFetchRequest<NSFetchRequestResult> = Dose.fetchRequest()
        request.predicate = NSPredicate(format: "medicine == %@", argumentArray: [med])
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                   managedObjectContext: cdStack.context,
                                                                   sectionNameKeyPath: "date",
                                                                   cacheName: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: false)
        refreshView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func refreshView() {
        displayEmptyView()
        
//        DispatchQueue.global(qos: .userInitiated).async {
//            print("Backup Thread")
//            if self.loadHistory() {
//                DispatchQueue.main.async {
//                    print("Main thread")
//                    self.displayEmptyView()
//                }
//            }
//        }
    }
    
//    func loadHistory() -> Bool {
//        if var historyArray = med.doseHistory?.array as? [Dose] {
//            print("Loading history")
//
//            // Clear history
//            history.removeAll()
//
//            // Sort history array
//            historyArray.sort(by: { $0.date.compare($1.date as Date) == .orderedDescending })
//
//            // Get dates in history
//            if emptyDates == true {
//                // Get all dates from today to last dose, including empty dates
//                var date = Date()
//                while date.compare(historyArray.last!.date as Date) != .orderedAscending {
//                    dates.append(date)
//                    date = (cal as NSCalendar).date(byAdding: .day, value: -1, to: date, options: [])!
//                }
//            } else {
//                // Get dates as exclusive elements from first dose to last
//                var temp = Set<Date>()
//                for dose in historyArray {
//                    temp.insert(cal.startOfDay(for: dose.date as Date))
//                }
//
//                // Store dates in array
//                dates = temp.sorted(by: { $0.compare($1) == .orderedDescending })
//            }
//
//            // Store doses in history dictionary, with dates as keys
//            for date in dates {
//                let doses = historyArray.filter({cal.isDate($0.date as Date, inSameDayAs: date)})
//                history.updateValue(doses, forKey: date)
//            }
//
//            print("History loaded")
//            return true
//        }
//
//        return false
//    }
    
    func displayEmptyView() {
        if self.fetchedResultsController?.sections?.count == 0 {
            for button in self.normalButtons {
                button.isEnabled = false
            }
            
            // Create empty message
            if let emptyView = UINib(nibName: "HistoryEmptyView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView {
                tableView.separatorStyle = UITableViewCellSeparatorStyle.none
                tableView.backgroundView = emptyView
            }
        } else {
            for button in self.normalButtons {
                button.isEnabled = true
            }
            
            tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
            tableView.backgroundView = nil
        }
        
        tableView.reloadData()
    }

    
    // MARK: - Table headers
    
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        return dates.count
//    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let fc = fetchedResultsController {
            let sectionDate = fc.sections![section].name
            print(sectionDate)
            return sectionDate
            
            // TODO: Convert string to Date
//            if cal.isDateInToday(sectionDate) {
//                dateFormatter.timeStyle = DateFormatter.Style.none
//                dateFormatter.dateStyle = DateFormatter.Style.medium
//                return "Today  \(dateFormatter.string(from: sectionDate))"
//            } else if cal.isDateInYesterday(sectionDate) {
//                dateFormatter.timeStyle = DateFormatter.Style.none
//                dateFormatter.dateStyle = DateFormatter.Style.medium
//                return "Yesterday  \(dateFormatter.string(from: sectionDate))"
//            } else if sectionDate.isDateInLastWeek() {
//                dateFormatter.dateFormat = "EEEE  MMM d, YYYY"
//                return dateFormatter.string(from: sectionDate)
//            } else {
//                dateFormatter.dateFormat = "EEEE  MMM d, YYYY"
//                return dateFormatter.string(from: sectionDate)
//            }
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let fc = fetchedResultsController {
            let sectionDate = fc.sections![section].name
            let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
            
            // Set header title
            header.textLabel?.text = header.textLabel?.text?.uppercased()
            header.textLabel?.textColor = UIColor(white: 0.43, alpha: 1.0)
            
            if let text = header.textLabel?.text {
                let string = NSMutableAttributedString(string: text)
                string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 13.0), range: NSMakeRange(0, string.length))
                
                // TODO: Convert string to date
//                if cal.isDateInToday(sectionDate) {
//                    string.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.red, range: NSMakeRange(0, string.length))
//                }
                
                if let index = text.characters.index(of: " ") {
                    let pos = text.characters.distance(from: text.startIndex, to: index)
                    string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 13.0, weight: UIFont.Weight.semibold), range: NSMakeRange(0, pos))
                }
                
                header.textLabel?.attributedText = string
            }
        }
    }

    
    // MARK: - Table rows
    
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        let sectionDate = dates[section]
//
//        if let count = history[sectionDate]?.count {
//            return (count == 0) ? 1 : count
//        }
//
//        return 1
//    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let fc = fetchedResultsController {
            let count = fc.sections![indexPath.section].numberOfObjects
            return (count > 0) ? 55.0 : tableView.rowHeight
        }
        
        return tableView.rowHeight
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath)
        
        if let dose = self.fetchedResultsController!.object(at: indexPath) as? Dose {
            // Setup date formatter
            dateFormatter.timeStyle = DateFormatter.Style.short
            dateFormatter.dateStyle = DateFormatter.Style.none
            
            // Specify selection color
            cell.selectedBackgroundView = UIView()
            
            if dose.dosage > 0 {
                cell.textLabel?.textColor = UIColor.black
                cell.textLabel?.text = "\(dateFormatter.string(from: dose.date as Date))"
                cell.detailTextLabel?.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
                cell.detailTextLabel?.text = String(format:"%g %@", dose.dosage, dose.dosageUnit.units(dose.dosage))
            } else {
                cell.textLabel?.textColor = UIColor.lightGray
                cell.textLabel?.text = "Skipped (\(dateFormatter.string(from: dose.date as Date)))"
                cell.detailTextLabel?.text?.removeAll()
            }
        } else {
            cell.textLabel?.textColor = UIColor.lightGray
            cell.textLabel?.text = "No doses logged"
            cell.detailTextLabel?.text?.removeAll()
        }
        
        return cell
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        let sectionDate = dates[indexPath.section]
//        return history[sectionDate]?.count != 0
        return true
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
//        let sectionDate = dates[indexPath.section]
//        return history[sectionDate]?.count != 0
        return true
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
    
    
    // MARK: - Mail delegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Toolbar methods
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing == true {
            setToolbarItems(editButtons, animated: true)
        } else {
            setToolbarItems(normalButtons, animated: true)
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
    
    @IBAction func addDose() {
        performSegue(withIdentifier: "addDose", sender: self)
    }
    
    @objc func deleteDoses() {
        if let selectedRowIndexes = tableView.indexPathsForSelectedRows {
            for indexPath in selectedRowIndexes.reversed() {
                if let dose = self.fetchedResultsController!.object(at: indexPath) as? Dose {
                    if med.lastDose == dose {
                        _ = med.untakeLastDose(cdStack.context)
                    } else {
                        med.untakeDose(dose, moc: cdStack.context)
                    }
                    
                    cdStack.context.delete(dose)
                    cdStack.save()
                    
                }
            }

            displayEmptyView()
            
            updateDeleteButtonLabel()
            setEditing(false, animated: true)
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
        }
    }
    
    @objc func exportDoses() {
        if MFMailComposeViewController.canSendMail() {
            if let history = med.doseHistory?.array as? [Dose] {
                var contents = "\(med.name!)\r"
                    contents += "\(med.removeTrailingZero(med.dosage)) \(med.dosageUnit.units(med.dosage)) every "
                    contents += "\(med.removeTrailingZero(med.interval)) \(med.intervalUnit.units(med.interval))\r"
                    contents += "Date, Dosage\r"
                
                for dose in history.reversed() {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "YYYY-MM-dd h:mm:ss a"
                    
                    contents += "\(dateFormatter.string(from: dose.date as Date)), "
                    
                    if dose.dosage > 0 {
                        contents += "\(med.removeTrailingZero(dose.dosage)) \(dose.dosageUnit.units(dose.dosage))\r"
                    } else {
                        contents += "Skipped\r"
                    }
                        
                }
                
                if let data = contents.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                    let mc = MFMailComposeViewController()
                    mc.mailComposeDelegate = self
                    mc.setSubject("\(med.name!) Dose History")
                    mc.addAttachmentData(data, mimeType: "text/csv", fileName: "\(med.name!)_Dose_History.csv")
                    
                    self.present(mc, animated: true, completion: nil)
                }
            }
        } else {
            print("Can't send")
        }
    }
    
    
    // MARK: - Navigation methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addDose" {
            if let vc = segue.destination.childViewControllers[0] as? AddDoseTVC {
                vc.med = med
            }
        }
    }

}
