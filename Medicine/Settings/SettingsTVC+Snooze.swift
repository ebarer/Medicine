//
//  SettingsTVC+Snooze.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-21.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class SettingsTVC_Snooze: UITableViewController {
    
    let defaults = NSUserDefaults.standardUserDefaults()
    let snoozeArray: [Int] = [ 1, 2, 5, 10, 15, 30 ]

    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return snoozeArray.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("snoozeCell", forIndexPath: indexPath)
        
        let amount = snoozeArray[indexPath.row]
        var string = "\(amount) minute"
        if (amount < 1 || amount >= 2) { string += "s" }
        cell.textLabel?.text = string
        
        let selected = defaults.integerForKey("snoozeLength")
        if selected == snoozeArray[indexPath.row] {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        
        return cell
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let selection = tableView.indexPathForSelectedRow?.row {
            let amount = snoozeArray[selection]
            defaults.setInteger(amount, forKey: "snoozeLength")
            defaults.synchronize()
            
            if let dvc = segue.destinationViewController as? SettingsTVC {
                var string = "\(amount) minute"
                if (amount < 1 || amount >= 2) { string += "s" }
                dvc.snoozeLabel.text = string
            }
        }
    }
    
}