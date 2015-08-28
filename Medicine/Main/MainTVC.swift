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
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        // Add observeres for notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "internalNotification:", name: "medNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "takeMedicationNotification:", name: "takeDoseNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "snoozeReminderNotification:", name: "snoozeReminderNotification", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Retrieve all medications
        let request = NSFetchRequest(entityName:"Medicine")
        
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

    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return medication.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("medicationCell", forIndexPath: indexPath)
        let med = medication[indexPath.row]
        
        // Set medication name
        cell.textLabel?.text = med.name
        
        // Set medication subtitle to next dosage date
        if let date = med.nextDose() {
            cell.detailTextLabel?.text = String("Next dose: \(date)")
        } else {
            cell.detailTextLabel?.text = String("Tap to take next dose")
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
        print("\(fromIndexPath.row) - \(toIndexPath.row)")
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let med = medication[indexPath.row]
        
        let alert = UIAlertController(title: med.name, message: nil, preferredStyle: .ActionSheet)
        
        alert.addAction(UIAlertAction(title: "Info", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
            self.performSegueWithIdentifier("medicationDetails", sender: indexPath.row)
        }))
        
        alert.addAction(UIAlertAction(title: "Take Next", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
            med.takeNextDose(self.moc)
            self.appDelegate.saveContext()
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }))
        
        // If next dosage is set, allow user to clear notification
        if (med.dosageNext > 0.0) {
            alert.addAction(UIAlertAction(title: "Untake Last", style: .Destructive, handler: {(action) -> Void in
                
            }))
            
            alert.addAction(UIAlertAction(title: "Clear Notification", style: .Destructive, handler: {(action) -> Void in
                // Clear local notification
                med.cancelNotification()
                med.dosageNext = 0.0
                
                tableView.reloadData()
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
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Pass the selected object to the new view controller.
        let svc = segue.destinationViewController as! UINavigationController
        let tvc = svc.topViewController as! AddMedicationTVC
        
        let entity = NSEntityDescription.entityForName("Medicine", inManagedObjectContext: moc)
        let temp = Medicine(entity: entity!, insertIntoManagedObjectContext: moc)
        tvc.med = temp
    }
    
    
    @IBAction func unwindForAdd(unwindSegue: UIStoryboardSegue) {
        let svc = unwindSegue.sourceViewController as! AddMedicationTVC
        
        if let addMed = svc.med {
            medication.append(addMed)
            appDelegate.saveContext()
            self.tableView.reloadData()
        }
    }
    
    @IBAction func unwindForCancel(unwindSegue: UIStoryboardSegue) {
        let svc = unwindSegue.sourceViewController as! AddMedicationTVC
    }
    
    
    // MARK: - Local Notifications
    
    func internalNotification(notification: NSNotification) {
        if let id = notification.userInfo!["id"] as? String {
            let medQuery = medication.filter{ $0.medicineID == id }.first
            if let med = medQuery {
                let message = String(format:"Time to take %g %@ of %@", med.dosageAmount, med.dosageType, med.name!)
                
                let alert = UIAlertController(title: "Take \(med.name!)", message: message, preferredStyle: .Alert)
                
                alert.addAction(UIAlertAction(title: "Take Dose", style: .Default, handler: {(action) -> Void in
                    self.takeMedicationNotification(notification)
                }))
                
                alert.addAction(UIAlertAction(title: "Snooze", style: .Cancel, handler: {(action) -> Void in
                    self.snoozeReminderNotification(notification)
                }))
                
                alert.view.tintColor = UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0)
                presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    func takeMedicationNotification(notification: NSNotification) {
        if let id = notification.userInfo!["id"] as? String {
            let medQuery = medication.filter{ $0.medicineID == id }.first
            if let med = medQuery {
                med.takeNextDose(moc)
                appDelegate.saveContext()
                self.tableView.reloadData()
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
