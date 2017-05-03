//
//  SettingsTVC+Sort.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-21.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class SettingsTVC_Sort: UITableViewController {

    let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine")!
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == defaults.integer(forKey: "sortOrder") {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.none
        }
    }

    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let selection = tableView.indexPathForSelectedRow?.row {
            defaults.set(selection, forKey: "sortOrder")
            defaults.synchronize()
            
            if let dvc = segue.destination as? SettingsTVC {
                switch(defaults.integer(forKey: "sortOrder")) {
                case SortOrder.manual.rawValue:
                    medication.sort(by: Medicine.sortByManual)
                    dvc.sortLabel.text = "Manually"
                case SortOrder.nextDosage.rawValue:
                    medication.sort(by: Medicine.sortByNextDose)
                    dvc.sortLabel.text = "Next Dosage"
                default: break
                }
            }
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
        }
    }

}
