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
        let request: NSFetchRequest<NSFetchRequestResult> = Dose.fetchRequest()
        request.predicate = NSPredicate(format: "medicine.medicineID == %@", argumentArray: [med.medicineID])
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
        return 80.0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableCell(withIdentifier: "headerCell")?.contentView else {
            return nil
        }
        
        let border = CALayer()
        border.backgroundColor = UIColor(white: 0.86, alpha: 1).cgColor
        border.frame = CGRect(x: 0, y: headerView.frame.height - 0.5, width: headerView.frame.width, height: 0.5)
        headerView.layer.addSublayer(border)
        
        guard let dayLabel = headerView.viewWithTag(1) as? UILabel else {
            return nil
        }
        
        dayLabel.textColor = UIColor.darkGray
        
        guard let dateLabel = headerView.viewWithTag(2) as? UILabel else {
            return nil
        }
        
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
        footerView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        
        let border = CALayer()
        border.backgroundColor = UIColor(white: 0.86, alpha: 1).cgColor
        border.frame = CGRect(x: 0, y: 0, width: footerView.frame.width, height: 0.5)
        footerView.layer.addSublayer(border)
        
        return footerView
    }

    
    // MARK: - Table rows
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let fc = fetchedResultsController {
            let count = fc.sections![indexPath.section].numberOfObjects
            return (count > 0) ? 50.0 : tableView.rowHeight
        }
        
        return tableView.rowHeight
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath) as! HistoryCell
        
        if let dose = self.fetchedResultsController!.object(at: indexPath) as? Dose {
            // Specify selection color
            cell.selectedBackgroundView = UIView()
            cell.historyLabel?.isHidden = true
            
            if dose.dosage > 0 {
                cell.dateLabel?.text = dose.date.string(timeStyle: .short)
                
                cell.medLabel?.text = String(format:"%g %@", dose.dosage, dose.dosageUnit.units(dose.dosage))
                cell.medLabel?.textColor = UIColor.medRed
            } else {
                cell.dateLabel?.text = dose.date.string(timeStyle: .short)
                cell.dateLabel?.textColor = UIColor(white: 0, alpha: 0.2)
                
                cell.medLabel?.text = "Skipped"
                cell.medLabel?.textColor = UIColor(white: 0, alpha: 0.2)
            }
        } else {
            cell.dateLabel?.isHidden = true
            
            cell.medLabel?.text = "No doses logged"
            cell.medLabel?.textColor = UIColor(white: 0, alpha: 0.2)
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
                self.fetchedResultsController?.delegate = nil
                vc.med = med
            }
        }
    }

}
