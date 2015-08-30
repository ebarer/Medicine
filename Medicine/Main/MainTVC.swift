//
//  MainTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-27.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class MainTVC: UITableViewController {
    
    var medication = [Medicine]()
    
    // MARK: - Helper variables
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Remove header
        tableView.tableHeaderView = UIView(frame: CGRectMake(0.0, 0.0, tableView.bounds.size.width, 0.01))
        
        // Table modifications
        self.clearsSelectionOnViewWillAppear = false
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        // Add observeres for notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "internalNotification:", name: "medNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "takeMedicationNotification:", name: "takeDoseNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "snoozeReminderNotification:", name: "snoozeReminderNotification", object: nil)
        
        // Cancel all notifications
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        // Load medications
        let request = NSFetchRequest(entityName:"Medicine")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        
        do {
            let fetchedResults = try moc.executeFetchRequest(request) as? [Medicine]
            
            if let results = fetchedResults {
                medication = results
                
                // Schedule all notifications
                for med in medication {
                    med.setNotification()
                }
            }
        } catch {
            print("Could not fetch medication.")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return medication.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100.0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("medicationCell", forIndexPath: indexPath)
        let med = medication[indexPath.row]
        
        // Set medication name
        cell.textLabel?.text = med.name
        
        // Set medication subtitle to next dosage date
        if let date = med.nextDose {
            let dateFormatter = NSDateFormatter()
            // dateFormatter.dateFormat = "MMM d, h:mm a"
            dateFormatter.dateFormat = "h:mm a"
            
            let subtitle = NSMutableAttributedString()

            if (med.isOverdue) {
                subtitle.appendAttributedString(NSAttributedString(string: "Overdue: "))
                subtitle.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: NSMakeRange(0, 8))
            } else {
                subtitle.appendAttributedString(NSAttributedString(string: "Next dose: "))
                subtitle.addAttribute(NSForegroundColorAttributeName, value: UIColor.lightGrayColor(), range: NSMakeRange(0, 10))
            }
            
            subtitle.appendAttributedString(NSAttributedString(string: "\(dateFormatter.stringFromDate(date))"))
            
            cell.detailTextLabel?.attributedText = subtitle
        } else {
            cell.detailTextLabel?.attributedText = NSAttributedString(string: "Tap to take next dose", attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            moc.deleteObject(medication[indexPath.row])
            appDelegate.saveContext()
            medication.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        medication[fromIndexPath.row].sortOrder = Int16(toIndexPath.row)
        medication[toIndexPath.row].sortOrder = Int16(fromIndexPath.row)
        medication.sortInPlace({ $0.sortOrder < $1.sortOrder })
        appDelegate.saveContext()
    }
    
    
    // MARK: - Table view delegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let med = medication[indexPath.row]
        
        if (tableView.editing == false) {
            let alert = UIAlertController(title: med.name, message: nil, preferredStyle: .ActionSheet)
            
            alert.addAction(UIAlertAction(title: "Take Next", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
                // TODO: Handle false by displaying error "Medication already taken within last 5 minutes. If error, untake last dose."
                if (med.takeNextDose(self.moc)) {
                    self.appDelegate.saveContext()
                    tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                } else {
                    tableView.deselectRowAtIndexPath(indexPath, animated: true)
                }
            }))
            
            // If next dosage is set, allow user to clear notification
            if (med.nextDose != nil) {
                alert.addAction(UIAlertAction(title: "Untake Last", style: .Destructive, handler: {(action) -> Void in
                    if (med.untakeLastDose(self.moc)) {
                        self.appDelegate.saveContext()
                        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                    } else {
                        tableView.deselectRowAtIndexPath(indexPath, animated: true)
                    }
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: {(action) -> Void in
                self.moc.deleteObject(self.medication[indexPath.row])
                self.appDelegate.saveContext()
                self.medication.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {(action) -> Void in
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }))
            
            alert.view.tintColor = UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0)
            presentViewController(alert, animated: true, completion: nil)
        } else {
            self.performSegueWithIdentifier("editMedication", sender: indexPath.row)
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addMedication" {
            let entity = NSEntityDescription.entityForName("Medicine", inManagedObjectContext: moc)
            let temp = Medicine(entity: entity!, insertIntoManagedObjectContext: moc)
            
            let vc = segue.destinationViewController as! UINavigationController
            let addVC = vc.topViewController as! AddMedicationTVC
            addVC.title = "New Medication"
            addVC.med = temp
        }
        
        if segue.identifier == "editMedication" {
            let vc = segue.destinationViewController as! UINavigationController
            let addVC = vc.topViewController as! AddMedicationTVC
            addVC.title = "Edit Medication"
            addVC.med = medication[sender as! Int]
            addVC.editMode = true
        }
        
        if segue.identifier == "viewMedicationDetails" {
            let vc = segue.destinationViewController as! HistoryTVC
            if let index = self.tableView.indexPathForCell(sender as! UITableViewCell) {
                vc.med = medication[index.row]
                vc.moc = self.moc
            }
        }
    }
    
    @IBAction func medicationUnwindAdd(unwindSegue: UIStoryboardSegue) {
        let svc = unwindSegue.sourceViewController as! AddMedicationTVC
        
        if let addMed = svc.med {
            if svc.editMode == false {
                addMed.sortOrder = Int16(medication.count + 1)
                medication.append(addMed)
            }
            
            appDelegate.saveContext()
            self.tableView.reloadData()
        }
    }
    
    @IBAction func medicationUnwindCancel(unwindSegue: UIStoryboardSegue) {}
    
    
    // MARK: - Local Notifications
    
    func internalNotification(notification: NSNotification) {
        if let id = notification.userInfo!["id"] as? String {
            let medQuery = medication.filter{ $0.medicineID == id }.first
            if let med = medQuery {
                if let name = med.name {
                    let message = String(format:"Time to take %g %@ of %@", med.dosage, med.dosageUnit.units(med.dosage), name)
                    
                    let alert = UIAlertController(title: "Take \(name) \(med.lastDose?.date)", message: message, preferredStyle: .Alert)
                    
                    alert.addAction(UIAlertAction(title: "Take Dose", style: .Default, handler: {(action) -> Void in
                        self.takeMedicationNotification(notification)
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Snooze", style: .Cancel, handler: {(action) -> Void in
                        self.snoozeReminderNotification(notification)
                    }))
                    
                    alert.view.tintColor = UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0)
                    
                    // TODO: Don't display if not front most VC
                    presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func takeMedicationNotification(notification: NSNotification) {
        if let id = notification.userInfo!["id"] as? String {
            let medQuery = medication.filter{ $0.medicineID == id }.first
            if let med = medQuery {
                if (med.takeNextDose(self.moc)) {
                    self.appDelegate.saveContext()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func snoozeReminderNotification(notification: NSNotification) {
        if let info = notification.userInfo {
            if let id = info["id"] as? String {
                let medQuery = medication.filter{ $0.medicineID == id }.first
                if let med = medQuery {
                    med.snoozeNotification()
                    appDelegate.saveContext()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
}
