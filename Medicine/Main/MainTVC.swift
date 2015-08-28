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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let request = NSFetchRequest(entityName:"Medicine")
        
        do {
            let fetchedResults = try moc.executeFetchRequest(request) as? [Medicine]
            
            if let results = fetchedResults {
                medication = results
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
        cell.textLabel?.text = medication[indexPath.row].name
        return cell
    }
    
    // MARK: - Allow editing table rows
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            moc.deleteObject(medication[indexPath.row])
            appDelegate.saveContext();

            medication.removeAtIndex(indexPath.row)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    // MARK: - Allow rearranging table rows
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        print("\(fromIndexPath.row) - \(toIndexPath.row)")
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Pass the selected object to the new view controller.
        let svc = segue.destinationViewController as! UINavigationController
        let tvc = svc.topViewController as! AddMedicationTVC
        
        let entity = NSEntityDescription.entityForName("Medicine", inManagedObjectContext: moc)
        let temp = Medicine(entity: entity!, insertIntoManagedObjectContext: moc)
        tvc.med = temp
        
        print("Display add medication VC (temp var passed).")
    }
    
    
    @IBAction func unwindForAdd(unwindSegue: UIStoryboardSegue) {
        let svc = unwindSegue.sourceViewController as! AddMedicationTVC
        print(svc.med?.name)
        
        if let addMed = svc.med {
            medication.append(addMed)
            appDelegate.saveContext();
            self.tableView.reloadData()
        }
        
        print("Add medication to persistent stores.")
    }
    
    @IBAction func unwindForCancel(unwindSegue: UIStoryboardSegue) {
        let svc = unwindSegue.sourceViewController as! AddMedicationTVC
        print(svc.med?.name)
        print("Cancel add medication.")
    }
    
}
