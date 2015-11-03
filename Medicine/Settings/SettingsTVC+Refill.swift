//
//  SettingsTVC+Refill.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-21.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class SettingsTVC_Refill: UITableViewController {
    
    let defaults = NSUserDefaults(suiteName: "group.com.ebarer.Medicine")!
    let refillArray: [Int] = [ 1, 2, 3, 4, 5, 6, 7]
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return refillArray.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("refillCell", forIndexPath: indexPath)
        
        let amount = refillArray[indexPath.row]
        var string = "\(amount) day"
        if (amount < 1 || amount >= 2) { string += "s" }
        cell.textLabel?.text = string
        
        let selected = defaults.integerForKey("refillTime")
        if selected == refillArray[indexPath.row] {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        
        return cell
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let selection = tableView.indexPathForSelectedRow?.row {
            let amount = refillArray[selection]
            defaults.setInteger(amount, forKey: "refillTime")
            defaults.synchronize()
            
            if let dvc = segue.destinationViewController as? SettingsTVC {
                var string = "\(amount) day"
                if (amount < 1 || amount >= 2) { string += "s" }
                dvc.refillLabel.text = string
            }
        }
    }
    
}