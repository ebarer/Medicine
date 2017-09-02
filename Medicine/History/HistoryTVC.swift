//
//  HistoryTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-28.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData
import MessageUI

class HistoryTVC: CoreDataTableViewController, MFMailComposeViewControllerDelegate {
    
    // MARK: - Helper variables
    let cdStack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    let cal = Calendar.current
    let dateFormatter = DateFormatter()

    var editButtons = [UIBarButtonItem]()
    
    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.cellLayoutMarginsFollowReadableWidth = true
        
        // Modify VC
        self.view.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        
        self.navigationController?.toolbar.isTranslucent = true
        self.navigationController?.toolbar.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        // Configure toolbar buttons
        let fixedButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let exportButton = UIBarButtonItem(title: "Export", style: UIBarButtonItemStyle.plain, target: self, action: #selector(exportDoses))
        let deleteButton = UIBarButtonItem(title: "Delete", style: UIBarButtonItemStyle.plain, target: self, action: #selector(deleteDoses))
        deleteButton.isEnabled = false
        editButtons.append(deleteButton)
        editButtons.append(fixedButton)
        editButtons.append(exportButton)
        setToolbarItems(editButtons, animated: true)
        
        // Add observeres for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(refreshView), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        // Define request for Doses
        let request: NSFetchRequest<NSFetchRequestResult> = Dose.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = 300

        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                   managedObjectContext: cdStack.context,
                                                                   sectionNameKeyPath: "dateSection",
                                                                   cacheName: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func refreshView() {
        displayEmptyView()
    }

    func displayEmptyView() {
        let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
        if let count = try? cdStack.context.count(for: request), count == 0 {
            navigationItem.leftBarButtonItem?.isEnabled = false
            navigationItem.rightBarButtonItem?.isEnabled = false
            
            if let emptyView = UINib(nibName: "MainEmptyView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView {
                tableView.backgroundView = emptyView
            }
        } else {
            if self.fetchedResultsController?.sections?.count == 0 {
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
        }
        
        tableView.reloadData()
    }
    
    
    // MARK: - Table headers

    // Ensure index bar (right side) doesn't appear
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 85.0
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
                return "Today\n\(dateFormatter.string(from: sectionDate))"
            } else if cal.isDateInYesterday(sectionDate) {
                dateFormatter.timeStyle = DateFormatter.Style.none
                dateFormatter.dateStyle = DateFormatter.Style.medium
                return "Yesterday\n\(dateFormatter.string(from: sectionDate))"
            } else if sectionDate.isDateInLastWeek() {
                dateFormatter.dateFormat = "EEEE\nMMMM d, YYYY"
                return dateFormatter.string(from: sectionDate)
            } else {
                dateFormatter.dateFormat = "EEEE\nMMMM d, YYYY"
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
            header.textLabel?.textColor = UIColor.lightGray
            header.textLabel?.textAlignment = .left
            
            if let text = header.textLabel?.text {
                let string = NSMutableAttributedString(string: text)
                string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 14.0), range: NSMakeRange(0, string.length))
                
                if let index = text.characters.index(of: "\n") {
                    let pos = text.characters.distance(from: text.startIndex, to: index)
                    string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 20.0, weight: UIFont.Weight.semibold), range: NSMakeRange(0, pos))
                    string.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(white: 0.22, alpha: 1), range: NSMakeRange(0, pos))
                    
                    if Calendar.current.isDateInToday(sectionDate) {
                        string.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0), range: NSMakeRange(0, pos))
                    }
                }
                
                header.textLabel?.attributedText = string
            }
        }
    }

    
    // MARK: - Table rows
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let fc = fetchedResultsController {
            let count = fc.sections![indexPath.section].numberOfObjects
            return (count > 0) ? 60.0 : tableView.rowHeight
        }
        
        return tableView.rowHeight
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath) as! HistoryCell
        
        if let dose = self.fetchedResultsController!.object(at: indexPath) as? Dose, let med = dose.medicine {
            // Setup date formatter
            dateFormatter.timeStyle = DateFormatter.Style.short
            dateFormatter.dateStyle = DateFormatter.Style.none
            
            // Specify selection color
            cell.selectedBackgroundView = UIView()
            
            if dose.dosage > 0 {
                cell.dateLabel?.text = dateFormatter.string(from: dose.date)
                
                cell.medLabel?.text = med.name
                
                cell.historyLabel?.text = String(format:"%g %@", dose.dosage, dose.dosageUnit.units(dose.dosage))
            } else {
                cell.dateLabel?.text = dateFormatter.string(from: dose.date)
                cell.dateLabel?.textColor = UIColor(white: 0, alpha: 0.2)
                
                cell.medLabel?.text = med.name
                cell.medLabel?.textColor = UIColor(white: 0, alpha: 0.2)
                
                cell.historyLabel?.text = "Skipped"
                cell.historyLabel?.textColor = UIColor(white: 0, alpha: 0.2)
            }
        } else {
            cell.dateLabel?.isHidden = true
            
            cell.medLabel?.text = "No doses logged"
            cell.medLabel?.textColor = UIColor(white: 0, alpha: 0.2)

            cell.historyLabel?.isHidden = true
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
    
    @objc func deleteDoses() {
        if let selectedRowIndexes = tableView.indexPathsForSelectedRows {
            for indexPath in selectedRowIndexes.reversed() {
                if let dose = self.fetchedResultsController!.object(at: indexPath) as? Dose {
                    let med = dose.medicine!
                    
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
        self.setEditing(false, animated: true)
        
        if MFMailComposeViewController.canSendMail() {
            if let history = self.fetchedResultsController?.fetchedObjects as? [Dose] {
                var contents = "Date, Medicine, Dosage\r"

                for dose in history.reversed() {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "YYYY-MM-dd h:mm a"

                    contents += "\(dateFormatter.string(from: dose.date as Date)), "
                    
                    if let name = dose.medicine?.name {
                        contents += "\(name), "
                    } else {
                        contents += "(Unknown), "
                    }

                    if dose.dosage > 0 {
                        contents += "\(dose.dosage.removeTrailingZero()) \(dose.dosageUnit.units(dose.dosage))\r"
                    } else {
                        contents += "Skipped\r"
                    }
                }

                if let data = contents.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                    let mc = MFMailComposeViewController()
                    mc.mailComposeDelegate = self
                    mc.setSubject("Dose History")
                    mc.addAttachmentData(data, mimeType: "text/csv", fileName: "Dose_History.csv")

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
