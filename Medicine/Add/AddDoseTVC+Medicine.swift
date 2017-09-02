//
//  AddDoseTV+Medicine.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-21.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class AddDoseTVC_Medicine: CoreDataTableViewController {

    // MARK: - Helper variables
    var selectedMed: Medicine?
    let cdStack = (UIApplication.shared.delegate as! AppDelegate).stack
    let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create fetch request
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Medicine.fetchRequest()
        
        if defaults.integer(forKey: "sortOrder") == SortOrder.nextDosage.rawValue {
            // Sort by next dose
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "reminderEnabled", ascending: false),
                NSSortDescriptor(key: "hasNextDose", ascending: false),
                NSSortDescriptor(key: "dateNextDose", ascending: true),
                NSSortDescriptor(key: "dateLastDose", ascending: false)
            ]
        } else {
            // Sort by manually defined sort order
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        }
        
        // Create the FetchedResultsController
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                   managedObjectContext: cdStack.context,
                                                                   sectionNameKeyPath: nil,
                                                                   cacheName: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "medicineCell", for: indexPath)
        
        if let med = self.fetchedResultsController!.object(at: indexPath) as? Medicine {
            cell.textLabel?.text = med.name
            if med == selectedMed {
                cell.accessoryType = .checkmark
            }
        }
        
        return cell
    }

    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let item = tableView.indexPathForSelectedRow?.row {
            let indexPath = IndexPath(item: item, section: 0)
            if let med = self.fetchedResultsController!.object(at: indexPath) as? Medicine {
                self.selectedMed = med
            }
        }
    }

}
