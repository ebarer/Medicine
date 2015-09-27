//
//  SettingsTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-21.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class SettingsTVC: UITableViewController {

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let defaults = NSUserDefaults.standardUserDefaults()
    
    
    // MARK: - Outlets
    
    @IBOutlet var sortLabel: UILabel!
    @IBOutlet var snoozeLabel: UILabel!
    @IBOutlet var versionString: UILabel!
    @IBOutlet var copyrightString: UILabel!

    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setLabels()
        
        // Set version string
        let dictionary = NSBundle.mainBundle().infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        versionString.text = "Medicine Manager \(version) (\(build))"
        
        // Set copyright string
        if let year = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)?.component(NSCalendarUnit.Year, fromDate: NSDate()) {
            copyrightString.text = "Elliot Barer © \(year)"
        } else {
            copyrightString.text = "© Elliot Barer"
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        if let index = tableView.indexPathForSelectedRow {
            self.tableView.deselectRowAtIndexPath(index, animated: animated)
        }
        
        setLabels()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setLabels() {
        // Set sort label
        switch(defaults.integerForKey("sortOrder")) {
        case 0:
            sortLabel.text = "Manually"
        case 1:
            sortLabel.text = "Next Dosage"
        default: break
        }
        
        // Set snooze label
        var amount = defaults.integerForKey("snoozeLength")
        
        if amount == 0 {
            amount = 5
        }
        
        var string = "\(amount) minute"
        if (amount < 1 || amount >= 2) { string += "s" }
        snoozeLabel.text = string
    }
    
    
    // MARK: - Table view delegate
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Hide console and help buttons if debug disabled        
        if defaults.boolForKey("debug") == true {
            return 3
        }
        
        return 2
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath == NSIndexPath(forRow: 0, inSection: 1) {
            let deleteAlert = UIAlertController(title: "Reset Data and Settings?", message: "This will permanently delete all medication, history, and preferences.", preferredStyle: UIAlertControllerStyle.Alert)
            
            deleteAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {(action) -> Void in
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }))
            
            deleteAlert.addAction(UIAlertAction(title: "Reset Data and Settings", style: .Destructive, handler: {(action) -> Void in
                self.deleteAll()
            }))
            
            deleteAlert.view.tintColor = UIColor.grayColor()
            self.presentViewController(deleteAlert, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - Helper methods
    
    func deleteAll() {
        let moc = appDelegate.managedObjectContext
        let request = NSFetchRequest(entityName:"Medicine")
        
        do {
            let fetchedResults = try moc.executeFetchRequest(request) as? [Medicine]
            
            // Delete all medications and corresponding history
            if let results = fetchedResults {
                for med in results {
                    moc.deleteObject(med)
                }
            }
            
            appDelegate.saveContext()
            
            // Reset preferences
            defaults.setBool(false, forKey: "firstLaunch")
            defaults.setInteger(0, forKey: "sortOrder")
            defaults.setInteger(5, forKey: "snoozeLength")
            defaults.synchronize()
            
            // Show reset confirmation
            let confirmationAlert = UIAlertController(title: "Reset Complete", message: "All medication, history, and preferences have been reset.", preferredStyle: UIAlertControllerStyle.Alert)
            
            confirmationAlert.addAction(UIAlertAction(title: "Quit Medicine Manager", style: UIAlertActionStyle.Destructive, handler: {(action) -> Void in
                exit(0)
            }))
            
            confirmationAlert.view.tintColor = UIColor.grayColor()
            self.presentViewController(confirmationAlert, animated: true, completion: nil)
        } catch {
            print("Could not fetch medication.")
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {}
    
    @IBAction func settingsUndwind(unwindSegue: UIStoryboardSegue) {}

}
