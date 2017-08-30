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
    
    // MARK: - Helper variables
    let cdStack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    let cal = Calendar.current
    let dateFormatter = DateFormatter()
    
    var normalButtons = [UIBarButtonItem]()
    var editButtons = [UIBarButtonItem]()
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        // Define request for Doses
        let cutoffDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        let request: NSFetchRequest<NSFetchRequestResult> = Dose.fetchRequest()
        request.predicate = NSPredicate(format: "medicine.medicineID == %@ && date >= %@",
                                        argumentArray: [med.medicineID, cutoffDate])
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = 300

        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                   managedObjectContext: cdStack.context,
                                                                   sectionNameKeyPath: "dateSection",
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
    }
    
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

    // Ensure index bar (right side) doesn't appear
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let fc = fetchedResultsController {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss ZZZ"
            guard let sectionDate = dateFormatter.date(from: fc.sections![section].name) else {
                return nil
            }
            
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
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let fc = fetchedResultsController {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss ZZZ"
            guard let sectionDate = dateFormatter.date(from: fc.sections![section].name) else {
                return
            }
            
            let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
            
            // Set header title
            header.textLabel?.text = header.textLabel?.text?.uppercased()
            header.textLabel?.textColor = UIColor(white: 0.43, alpha: 1.0)
            
            if let text = header.textLabel?.text {
                let string = NSMutableAttributedString(string: text)
                string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 13.0), range: NSMakeRange(0, string.length))
                
                if Calendar.current.isDateInToday(sectionDate) {
                    string.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.red, range: NSMakeRange(0, string.length))
                }
                
                if let index = text.characters.index(of: " ") {
                    let pos = text.characters.distance(from: text.startIndex, to: index)
                    string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 13.0, weight: UIFont.Weight.semibold), range: NSMakeRange(0, pos))
                }
                
                header.textLabel?.attributedText = string
            }
        }
    }

    
    // MARK: - Table rows
    
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
        return true
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
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
                    contents += "\(med.dosage.removeTrailingZero()) \(med.dosageUnit.units(med.dosage)) "
                
                if med.reminderEnabled {
                    contents += "every \(med.interval.removeTrailingZero()) \(med.intervalUnit.units(med.interval))\r"
                } else {
                    contents += "as needed\r"
                }
                
                contents += "Date, Dosage\r"
                
                for dose in history.reversed() {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "YYYY-MM-dd h:mm a"
                    
                    contents += "\(dateFormatter.string(from: dose.date as Date)), "
                    
                    if dose.dosage > 0 {
                        contents += "\(med.dosage.removeTrailingZero()) \(dose.dosageUnit.units(dose.dosage))\r"
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
