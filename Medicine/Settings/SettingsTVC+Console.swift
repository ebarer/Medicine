//
//  SettingsTVC+Console.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-22.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class SettingsTVC_Console: UITableViewController {

    let cal = Calendar.current
    let dateFormatter = DateFormatter()

    var notifications = UIApplication.shared.scheduledLocalNotifications!
    var console = [(name: String, date: String, id: String)]()
    
    let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine")!

    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = loadNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if loadNotifications() {
            tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func reloadView() {
        if loadNotifications() {
            tableView.reloadData()
        }
    }
    
    func loadNotifications() -> Bool {
        notifications = UIApplication.shared.scheduledLocalNotifications!
        
        if notifications.count != 0 {
            console.removeAll()
            
            for (_, notification) in notifications.enumerated() {
                if let id = notification.userInfo?["id"] {
                    if let med = Medicine.getMedicine(arr: medication, id: id as! String) {
                        dateFormatter.dateStyle = DateFormatter.Style.medium
                        dateFormatter.timeStyle = DateFormatter.Style.short
                        console.append((med.name!, dateFormatter.string(from: notification.fireDate!), id as! String))
                    }
                }
            }
            
            return true
        }
        
        return false
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
        case 0:
            return medication.count
        case 1:
            return console.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch(section) {
        case 0:
            return "Medication"
        case 1:
            if console.count == 0 {
                return "No scheduled notifications"
            }
            
            return "Scheduled Notifications"
        case 2:
            return "Background Rescheduling Calls"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "consoleCell", for: indexPath)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.medium
        
        switch(indexPath.section) {
        case 0:
            let name = medication[indexPath.row].name!
            let attributedString = NSMutableAttributedString(string: name)
            attributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0), range: NSMakeRange(0, name.characters.count))
            cell.textLabel?.attributedText = attributedString
            cell.detailTextLabel?.text = medication[indexPath.row].medicineID
        case 1:
            let txt = console[indexPath.row]
            let attributedString = NSMutableAttributedString(string: "\(txt.name) - \(txt.date)")
            attributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0), range: NSMakeRange(0, txt.name.characters.count))
            cell.textLabel?.attributedText = attributedString
            cell.detailTextLabel?.text = txt.id
        default: break
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch(indexPath.section) {
        case 2:
            return 44.0
        default:
            return 70.0
        }
    }

}
