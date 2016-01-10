//
//  SettingsTVC+Manage.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-11-07.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class SettingsTVC_Manage: UITableViewController {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext
    
    
    // MARK: - Initialization
    
    required init?(coder aDecoder: NSCoder) {
        moc = appDelegate.managedObjectContext
        super.init(coder: aDecoder)
    }
    
    
    // MARK: - View methods

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var request: NSFetchRequest?
        var set: String?
        
        switch indexPath {
        case NSIndexPath(forRow: 0, inSection: 0):
            performSegueWithIdentifier("viewCollection", sender: "Medicine")
        case NSIndexPath(forRow: 1, inSection: 0):
            set = "Medication"
            request = NSFetchRequest(entityName:"Medicine")
        case NSIndexPath(forRow: 0, inSection: 1):
            performSegueWithIdentifier("viewCollection", sender: "Dose")
        case NSIndexPath(forRow: 1, inSection: 1):
            set = "Doses"
            request = NSFetchRequest(entityName:"Dose")
        case NSIndexPath(forRow: 0, inSection: 2):
            performSegueWithIdentifier("viewCollection", sender: "Refill")
        case NSIndexPath(forRow: 1, inSection: 2):
            set = "Refills"
            request = NSFetchRequest(entityName:"Refill")
            for med in medication {
                med.prescriptionCount = 0.0
            }
        case NSIndexPath(forRow: 0, inSection: 3):
            print("Cancelling all notifications")
            UIApplication.sharedApplication().cancelAllLocalNotifications()
        default:
            break
        }
        
        if indexPath.row == 1 {
            if let request = request {
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                do {
                    try appDelegate.persistentStoreCoordinator.executeRequest(deleteRequest, withContext: moc)
                    appDelegate.saveContext()
                    print("Deleted all \(set!).")
                } catch {
                    print("Couldn't delete \(set!).")
                }
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let entity = sender as? String where segue.identifier == "viewCollection" {
            if let vc = segue.destinationViewController as? SettingsTVC_Collection {
                switch entity {
                case "Medicine":
                    vc.entityName = "Medicine"
                case "Dose":
                    vc.entityName = "Dose"
                case "Refill":
                    vc.entityName = "Refill"
                default:
                    break
                }
            }
        }
    }

}
