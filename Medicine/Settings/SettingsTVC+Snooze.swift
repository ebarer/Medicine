//
//  SettingsTVC+Snooze.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-21.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class SettingsTVC_Snooze: UITableViewController {
    
    let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine")!
    let snoozeArray: [Int] = [ 1, 2, 5, 10, 15, 30 ]

    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return snoozeArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "snoozeCell", for: indexPath)
        
        let amount = snoozeArray[indexPath.row]
        var string = "\(amount) minute"
        if (amount < 1 || amount >= 2) { string += "s" }
        cell.textLabel?.text = string
        
        let selected = defaults.integer(forKey: "snoozeLength")
        if selected == snoozeArray[indexPath.row] {
            cell.accessoryType = UITableViewCell.AccessoryType.checkmark
        }
        
        return cell
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let selection = tableView.indexPathForSelectedRow?.row {
            let amount = snoozeArray[selection]
            defaults.set(amount, forKey: "snoozeLength")
            defaults.synchronize()
            
            if let dvc = segue.destination as? SettingsTVC {
                var string = "\(amount) minute"
                if (amount < 1 || amount >= 2) { string += "s" }
                dvc.snoozeLabel.text = string
            }
        }
    }
    
}
