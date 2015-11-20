//
//  SettingsTVC_Collection.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-11-07.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class SettingsTVC_Collection: UITableViewController {

    var entityName: String?
    var collection: [AnyObject]?
    
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
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem()

        loadCollection()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Helper methods
    
    func loadCollection() {
        if let name = entityName {
            let request = NSFetchRequest(entityName: name)
            
            if let name = entityName {
                switch name {
                case "Medicine":
                    request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                case "History":
                    request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
                case "Prescription":
                    request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
                default:
                    break
                }
            }
            
            do {
                collection = try moc.executeFetchRequest(request)
            } catch {
                print("Could not fetch.")
            }
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = collection?.count {
            return count
        }
        
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("collectionCell", forIndexPath: indexPath)
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle

        if let name = entityName {
            switch name {
            case "Medicine":
                let med = collection![indexPath.row] as! Medicine
                cell.textLabel?.text = med.name!
                cell.detailTextLabel?.text = "\(med.prescriptionCount) \(med.dosageUnit.description) - \(med.medicineID)"
            case "History":
                let dose = collection![indexPath.row] as! History
                cell.textLabel?.text = dateFormatter.stringFromDate(dose.date)
                cell.detailTextLabel?.text = "\(dose.medicine!.name!) - \(dose.dosage) \(Doses(rawValue: dose.dosageUnitInt)!.description)"
            case "Prescription":
                let refill = collection![indexPath.row] as! Prescription
                cell.textLabel?.text = "\(refill.medicine!.name!) - \(refill.quantity * refill.conversion) \(refill.medicine!.dosageUnit.description)"
                cell.detailTextLabel?.text = dateFormatter.stringFromDate(refill.date) +
                                             " - \(refill.quantity) \(refill.quantityUnit.description) * \(refill.conversion) " +
                                             "\(refill.medicine!.dosageUnit.description)/\(refill.quantityUnit.description)"
            default:
                break
            }
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70.0
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            if let name = entityName {
                switch name {
                case "Medicine":
                    moc.deleteObject(collection![indexPath.row] as! NSManagedObject)
                    appDelegate.saveContext()
                    (self.tabBarController as! MainTBC).loadMedication()
                case "History":
                    let dose = collection![indexPath.row] as! History
                    dose.medicine?.untakeDose(dose, moc: moc)
                case "Prescription":
                    let refill = collection![indexPath.row] as! Prescription
                    refill.medicine?.removeRefill(refill, moc: moc)
                default:
                    break
                }
            }
            
            collection?.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }

}
