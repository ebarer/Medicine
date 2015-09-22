//
//  AddDoseTV+Medicine.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-21.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class AddDoseTV_Medicine: UITableViewController {

    var selectedMed: Medicine?
    var medication = [Medicine]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let moc = delegate.managedObjectContext
        
        // Load medications
        let request = NSFetchRequest(entityName:"Medicine")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
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

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return medication.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("medicineCell", forIndexPath: indexPath)
        
        cell.textLabel?.text = medication[indexPath.row].name
        
        if selectedMed == medication[indexPath.row] {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        
        return cell
    }

    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let selRow = tableView.indexPathForSelectedRow?.row {
            selectedMed = medication[selRow]
        }
    }

}
