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
    
    var normalButtons = [UIBarButtonItem]()
    var editButtons = [UIBarButtonItem]()
    
    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.cellLayoutMarginsFollowReadableWidth = true
        
        // Modify VC
        self.view.tintColor = UIColor.medRed
        self.navigationController?.toolbar.isTranslucent = true
        self.navigationController?.toolbar.tintColor = UIColor.medRed
        
        // Configure toolbar buttons
        let fixedButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let exportButton = UIBarButtonItem(title: "Export", style: UIBarButtonItem.Style.plain, target: self, action: #selector(exportDoses))
        let deleteButton = UIBarButtonItem(title: "Delete", style: UIBarButtonItem.Style.plain, target: self, action: #selector(deleteDoses))
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
        NotificationCenter.default.addObserver(self, selector: #selector(refreshView), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // Define request for Doses
        let request: NSFetchRequest<NSFetchRequestResult> = Dose.fetchRequest()
        request.predicate = NSPredicate(format: "medicine.medicineID == %@", argumentArray: [med.medicineID])
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = 300

        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                   managedObjectContext: CoreDataStack.shared.context,
                                                                   sectionNameKeyPath: "dateSection",
                                                                   cacheName: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: false)
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
        if self.fetchedResultsController?.sections?.count == 0 {
            for button in self.normalButtons {
                button.isEnabled = false
            }
            
            // Create empty message
            if let emptyView = UINib(nibName: "HistoryEmptyView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView {
                tableView.separatorStyle = .none
                tableView.backgroundView = emptyView
            }
        } else {
            for button in self.normalButtons {
                button.isEnabled = true
            }
            
            tableView.separatorStyle = .singleLine
            tableView.backgroundView = nil
        }
        
        tableView.reloadData()
    }

    
    // MARK: - Table headers

    // Ensure index bar (right side) doesn't appear
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableCell(withIdentifier: "headerCell")?.contentView else {
            return nil
        }
        
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
        return footerView
    }

    
    // MARK: - Table rows
        
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let fc = fetchedResultsController {
            let count = fc.sections![indexPath.section].numberOfObjects
            return (count > 0) ? 50.0 : tableView.rowHeight
        }
        
        return tableView.rowHeight
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath) as! HistoryCell
        cell.dateLabel?.textColor = UIColor.subtitleLabel
        cell.medLabel?.textColor = UIColor.subtitleLabel
        cell.historyLabel?.isHidden = true
        
        if let dose = self.fetchedResultsController!.object(at: indexPath) as? Dose {
            // Specify selection color
            cell.selectedBackgroundView = UIView()
            
            if dose.dosage > 0 {
                // Default
                cell.dateLabel?.text = dose.date.string(timeStyle: .short)
                cell.medLabel?.text = String(format:"%g %@", dose.dosage, dose.dosageUnit.units(dose.dosage))
                cell.medLabel?.textColor = UIColor.medRed
            } else {
                // Skipped
                cell.dateLabel?.text = dose.date.string(timeStyle: .short)
                cell.medLabel?.text = "Skipped"
            }
        } else {
            cell.dateLabel?.isHidden = true
            cell.medLabel?.text = "No doses logged"
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
                        _ = med.untakeLastDose(context: CoreDataStack.shared.context)
                    } else {
                        med.untakeDose(dose, context: CoreDataStack.shared.context)
                    }
                    
                    CoreDataStack.shared.context.delete(dose)
                }
            }
            
            CoreDataStack.shared.save()
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
            
            updateDeleteButtonLabel()
            setEditing(false, animated: true)
        }
    }
    
    @objc func exportDoses() {
        if MFMailComposeViewController.canSendMail() {
            let mc = MFMailComposeViewController()
            mc.mailComposeDelegate = self
            mc.setSubject("\(med.name!) Dose History")
            
            DispatchQueue.global(qos: .userInitiated).async {
                if let history = self.med.doseHistory?.array as? [Dose] {
                    var contents = "\(self.med.name!)\r"
                    contents += "\(self.med.dosage.removeTrailingZero()) \(self.med.dosageUnit.units(self.med.dosage)) "
                    
                    if self.med.reminderEnabled {
                        contents += "every \(self.med.interval.removeTrailingZero()) \(self.med.intervalUnit.units(self.med.interval))\r"
                    } else {
                        contents += "as needed\r"
                    }
                    
                    contents += "Date, Dosage\r"
                    
                    for dose in history.reversed() {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "YYYY-MM-dd h:mm a"
                        
                        contents += "\(dateFormatter.string(from: dose.date as Date)), "
                        
                        if dose.dosage > 0 {
                            contents += "\(self.med.dosage.removeTrailingZero()) \(dose.dosageUnit.units(dose.dosage))\r"
                        } else {
                            contents += "Skipped\r"
                        }
                    }
                    
                    if let data = contents.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                        DispatchQueue.main.async {
                            mc.addAttachmentData(data, mimeType: "text/csv", fileName: "\(self.med.name!)_Dose_History.csv")
                        }
                    }
                }
            }
                
            self.present(mc, animated: true, completion: nil)
        } else {
            NSLog("Export: Unable to export dose history for med (\(med.name!)): user unable to send mail.")
        }
    }
    
    
    // MARK: - Navigation methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addDose" {
            if let vc = segue.destination.children[0] as? AddDoseTVC {
                self.fetchedResultsController?.delegate = nil
                vc.med = med
            }
        }
    }

}
