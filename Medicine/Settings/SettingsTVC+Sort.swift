//
//  SettingsTVC+Sort.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-21.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class SettingsTVC_Sort: UITableViewController {

    let defaults = NSUserDefaults(suiteName: "group.com.ebarer.Medicine")!
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == defaults.integerForKey("sortOrder") {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
    }

    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let selection = tableView.indexPathForSelectedRow?.row {
            defaults.setInteger(selection, forKey: "sortOrder")
            defaults.synchronize()
            
            if let dvc = segue.destinationViewController as? SettingsTVC {
                switch(selection) {
                case 0:
                    dvc.sortLabel.text = "Manually"
                case 1:
                    dvc.sortLabel.text = "Next Dosage"
                default: break
                }
            }
        }
    }

}
