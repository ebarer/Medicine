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

    var editButtons = [UIBarButtonItem]()
    
    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.cellLayoutMarginsFollowReadableWidth = true
        
        // Modify VC
        self.view.tintColor = UIColor.medRed
        
        self.navigationController?.toolbar.isTranslucent = true
        self.navigationController?.toolbar.tintColor = UIColor.medRed
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        // Configure toolbar buttons
        let fixedButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let exportButton = UIBarButtonItem(title: "Export", style: UIBarButtonItem.Style.plain, target: self, action: #selector(exportDoses))
        let deleteButton = UIBarButtonItem(title: "Delete", style: UIBarButtonItem.Style.plain, target: self, action: #selector(deleteDoses))
        deleteButton.isEnabled = false
        
        editButtons.append(deleteButton)
        editButtons.append(fixedButton)
        editButtons.append(exportButton)
        
        setToolbarItems(editButtons, animated: true)
        
        // Add observeres for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(refreshView), name: NSNotification.Name(rawValue: "refreshView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshView), name: UIApplication.willEnterForegroundNotification, object: nil)
        
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.refreshView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func refreshView() {
        self.fetchedResultsController?.delegate = self
        self.executeSearch()
        displayEmptyView()
    }

    func displayEmptyView() {
        let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
        if let count = try? cdStack.context.count(for: request), count == 0 {
            navigationItem.leftBarButtonItem?.isEnabled = false
            navigationItem.rightBarButtonItem?.isEnabled = false
            
            if let emptyView = UINib(nibName: "MainEmptyView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView {
                tableView.backgroundView = emptyView
                tableView.separatorStyle = .none
            }
        } else {
            if self.fetchedResultsController?.sections?.count == 0 {
                navigationItem.leftBarButtonItem?.isEnabled = false
                navigationItem.rightBarButtonItem?.isEnabled = true
                
                // Create empty message
                if let emptyView = UINib(nibName: "HistoryEmptyView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView {
                    tableView.backgroundView = emptyView
                    tableView.separatorStyle = .none
                }
            } else {
                navigationItem.leftBarButtonItem?.isEnabled = true
                navigationItem.leftBarButtonItem?.isEnabled = true
                tableView.separatorStyle = .singleLine
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
        return 80.0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableCell(withIdentifier: "headerCell")?.contentView else {
            return nil
        }
        
        let border = CALayer()
        border.backgroundColor = UIColor.tableGroupedSeparator.cgColor
        border.frame = CGRect(x: 0, y: headerView.frame.height - 0.5, width: headerView.frame.width, height: 0.5)
        headerView.layer.addSublayer(border)
        
        guard let dayLabel = headerView.viewWithTag(1) as? UILabel else {
            return nil
        }
        
        dayLabel.textColor = UIColor.medGray1
        
        guard let dateLabel = headerView.viewWithTag(2) as? UILabel else {
            return nil
        }
        
        dateLabel.textColor = UIColor.medGray2

        if let fc = fetchedResultsController {
            guard let sectionDate = Date.fromString(fc.sections![section].name, withFormat: "YYYY-MM-dd HH:mm:ss ZZZ") else {
                return nil
            }
            
            if Calendar.current.isDateInToday(sectionDate) {
                dayLabel.textColor = UIColor.medRed
                dayLabel.text = "TODAY"
                dateLabel.text = sectionDate.string(withFormat: "MMMM d").uppercased()
            } else if Calendar.current.isDateInYesterday(sectionDate) {
                dayLabel.text = "YESTERDAY"
                dateLabel.text = sectionDate.string(withFormat: "MMMM d").uppercased()
            } else if sectionDate.isDateInLastWeek() {
                dayLabel.text = sectionDate.string(withFormat: "EEEE").uppercased()
                dateLabel.text = sectionDate.string(withFormat: "MMMM d").uppercased()
            } else {
                dayLabel.text = sectionDate.string(withFormat: "MMMM d, YYYY").uppercased()
                dateLabel.text = sectionDate.string(withFormat: "EEEE").uppercased()
            }
        }

        return headerView
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 5))
        footerView.backgroundColor = UIColor.tableGroupedBackground
        
        let border = CALayer()
        border.backgroundColor = UIColor.tableGroupedSeparator.cgColor
        border.frame = CGRect(x: 0, y: 0, width: footerView.frame.width, height: 0.5)
        footerView.layer.addSublayer(border)
        
        return footerView
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
        cell.dateLabel?.textColor = UIColor.subtitleLabel
        cell.medLabel?.textColor = UIColor.subtitleLabel
        cell.historyLabel?.textColor = UIColor.subtitleLabel
        
        if let dose = self.fetchedResultsController!.object(at: indexPath) as? Dose, let med = dose.medicine {
            // Specify selection color
            cell.selectedBackgroundView = UIView()
            
            if dose.dosage > 0 {
                // Default
                cell.dateLabel?.text = dose.date.string(timeStyle: .short)
                cell.medLabel?.text = med.name
                cell.medLabel?.textColor = UIColor.medRed
                cell.historyLabel?.text = String(format:"%g %@", dose.dosage, dose.dosageUnit.units(dose.dosage))
                cell.historyLabel?.textColor = UIColor.medRed
            } else {
                // Skipped
                cell.dateLabel?.text = dose.date.string(timeStyle: .short)
                cell.medLabel?.text = med.name
                cell.historyLabel?.text = "Skipped"
            }
        } else {
            // No doses
            cell.dateLabel?.isHidden = true
            cell.medLabel?.text = "No doses logged"
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableView.ScrollPosition.none)
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
                        _ = med.untakeLastDose(context: cdStack.context)
                    } else {
                        med.untakeDose(dose, context: cdStack.context)
                    }
                    
                    cdStack.context.delete(dose)
                }
            }
            
            cdStack.save()
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
            
            updateDeleteButtonLabel()
            setEditing(false, animated: true)
        }
    }
    
    @objc func exportDoses() {
        self.setEditing(false, animated: true)
        
        if MFMailComposeViewController.canSendMail() {
            let mc = MFMailComposeViewController()
            mc.mailComposeDelegate = self
            mc.setSubject("Dose History")
            
            DispatchQueue.global(qos: .userInitiated).async {
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
                        DispatchQueue.main.async {
                            mc.addAttachmentData(data, mimeType: "text/csv", fileName: "Dose_History.csv")
                        }
                    }
                }
            }
            
            self.present(mc, animated: true, completion: nil)
        } else {
            NSLog("Export", "Unable to export global history: user unable to send mail.")
        }
    }
    
    
    // MARK: - Navigation methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addDose" {
            if let vc = segue.destination.children[0] as? AddDoseTVC {
                self.fetchedResultsController?.delegate = nil
                vc.globalHistory = true
            }
        }
    }

}


// Protect against invalid arguments when deleting
extension Array {
    subscript (safe index: Int) -> Element? {
        return (indices ~= index) ? self[index] : nil
    }
}
