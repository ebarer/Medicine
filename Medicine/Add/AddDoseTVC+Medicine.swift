//
//  AddDoseTV+Medicine.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-21.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class AddDoseTVC_Medicine: UITableViewController {

    var selectedMed: Medicine?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return medication.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "medicineCell", for: indexPath)
        
        cell.textLabel?.text = medication[indexPath.row].name
        
        if selectedMed == medication[indexPath.row] {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        }
        
        return cell
    }

    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let selectedRow = tableView.indexPathForSelectedRow?.row {
            self.selectedMed = medication[selectedRow]
        }
    }

}
