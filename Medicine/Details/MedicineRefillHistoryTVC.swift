//
//  MedicineRefillHistoryTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-28.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData
import MessageUI

class MedicineRefillHistoryTVC: CoreDataTableViewController, MFMailComposeViewControllerDelegate {
    
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
        
        self.tableView.cellLayoutMarginsFollowReadableWidth = true
        
        // Modify VC
        self.title = "Refill History"
        self.view.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        self.navigationController?.toolbar.isTranslucent = true
        self.navigationController?.toolbar.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        
        // Configure toolbar buttons
        let fixedButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let exportButton = UIBarButtonItem(title: "Export", style: UIBarButtonItemStyle.plain, target: self, action: #selector(exportRefills))
        let deleteButton = UIBarButtonItem(title: "Delete", style: UIBarButtonItemStyle.plain, target: self, action: #selector(deleteRefills))
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
        let request: NSFetchRequest<NSFetchRequestResult> = Refill.fetchRequest()
        request.predicate = NSPredicate(format: "medicine.medicineID == %@", argumentArray: [med.medicineID])
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = 500
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                   managedObjectContext: cdStack.context,
                                                                   sectionNameKeyPath: "dateSection",
                                                                   cacheName: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: animated)
        displayEmptyView()
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
            header.textLabel?.textColor = UIColor(white: 0, alpha: 0.3)
            header.textLabel?.textAlignment = .left
            
            if let text = header.textLabel?.text {
                let string = NSMutableAttributedString(string: text)
                string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 14.0), range: NSMakeRange(0, string.length))
                
                if let index = text.characters.index(of: "\n") {
                    let pos = text.characters.distance(from: text.startIndex, to: index)
                    string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 20.0, weight: UIFont.Weight.semibold), range: NSMakeRange(0, pos))
                    string.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(white: 0, alpha: 0.7), range: NSMakeRange(0, pos))
                    
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
            return (count > 0) ? 50.0 : tableView.rowHeight
        }
        
        return tableView.rowHeight
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath) as! HistoryCell
        
        if let refill = self.fetchedResultsController!.object(at: indexPath) as? Refill {
            // Setup date formatter
            dateFormatter.timeStyle = DateFormatter.Style.short
            dateFormatter.dateStyle = DateFormatter.Style.none
            
            // Specify selection color
            cell.selectedBackgroundView = UIView()
            cell.historyLabel?.isHidden = true
            
            // Setup cell
            let refillAmount = (refill.quantity * refill.conversion).removeTrailingZero()
            var amount = "Added \(refillAmount) \(med.dosageUnit.units(med.prescriptionCount))"
            
            if refill.conversion != 1.0 {
                amount += " (\(refill.quantity.removeTrailingZero()) \(refill.quantityUnit.units(refill.quantity)))"
            }
            
            cell.dateLabel?.text = dateFormatter.string(from: refill.date)
            
            cell.medLabel?.text = amount
            cell.medLabel?.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        } else {
            cell.dateLabel?.isHidden = true
            
            cell.medLabel?.text = "No refills logged"
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
        deleteRefills()
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
    
    @IBAction func addRefill() {
        performSegue(withIdentifier: "addRefill", sender: self)
    }
    
    @objc func deleteRefills() {
        if let selectedRowIndexes = tableView.indexPathsForSelectedRows {
            for indexPath in selectedRowIndexes.reversed() {
                if let refill = self.fetchedResultsController!.object(at: indexPath) as? Refill {
                    med.removeRefill(refill, moc: cdStack.context)
                    
                    if tableView.numberOfRows(inSection: indexPath.section) == 1 {
                        tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
                    } else {
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
            }

            displayEmptyView()
            
            updateDeleteButtonLabel()
            setEditing(false, animated: true)
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
        }
    }
    
    @objc func exportRefills() {
        if MFMailComposeViewController.canSendMail() {
            if let history = med.refillHistory?.array as? [Refill] {
                var contents = "\(med.name!)\r"
                
                contents += "Date, Amount\r"
                
                for refill in history.reversed() {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "YYYY-MM-dd h:mm a"

                    contents += "\(dateFormatter.string(from: refill.date as Date)), "
                    contents += "\((refill.quantity * refill.conversion).removeTrailingZero()) \(med.dosageUnit.units(med.prescriptionCount))"
                    
                    if refill.conversion != 1.0 {
                        contents += " (\(refill.quantity.removeTrailingZero()) \(refill.quantityUnit.units(refill.quantity)))"
                    }
                    
                    contents += "\r"
                }
                
                if let data = contents.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                    let mc = MFMailComposeViewController()
                    mc.mailComposeDelegate = self
                    mc.setSubject("\(med.name!) Refill History")
                    mc.addAttachmentData(data, mimeType: "text/csv", fileName: "\(med.name!)_Refill_History.csv")
                    
                    self.present(mc, animated: true, completion: nil)
                }
            }
        } else {
            print("Can't send")
        }
    }
    
    
    // MARK: - Navigation methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addRefill" {
            if let vc = segue.destination.childViewControllers[0] as? AddRefillTVC {
                vc.med = med
            }
        }
    }
    
}
