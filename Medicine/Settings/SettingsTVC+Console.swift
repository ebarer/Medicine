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

    let cal = NSCalendar.currentCalendar()
    let dateFormatter = NSDateFormatter()

    var notifications = UIApplication.sharedApplication().scheduledLocalNotifications!
    var console = [(name: String, date: String, id: String)]()

    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadNotifications()
    }
    
    override func viewWillAppear(animated: Bool) {
        loadNotifications()
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
        notifications = UIApplication.sharedApplication().scheduledLocalNotifications!
        
        if notifications.count != 0 {
            console.removeAll()
            
            for (_, notification) in notifications.enumerate() {
                if let id = notification.userInfo?["id"] {
                    if let med = Medicine.getMedicine(arr: medication, id: id as! String) {
                        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
                        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
                        console.append((med.name!, dateFormatter.stringFromDate(notification.fireDate!), id as! String))
                    }
                }
            }
            
            return true
        }
        
        return false
    }

    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
        case 0:
            return medication.count
        case 1:
            return console.count
        case 2:
            return rescheduleDates.count
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch(section) {
        case 0:
            return "Medication"
        case 1:
            if console.count == 0 {
                return "No scheduled notifications"
            }
            
            return "Scheduled Notifications"
        case 2:
            return "Rescheduling Occurences"
        default:
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("consoleCell", forIndexPath: indexPath)
        
        switch(indexPath.section) {
        case 0:
            let name = medication[indexPath.row].name!
            let attributedString = NSMutableAttributedString(string: name)
            attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0), range: NSMakeRange(0, name.characters.count))
            cell.textLabel?.attributedText = attributedString
            cell.detailTextLabel?.text = medication[indexPath.row].medicineID
        case 1:
            let txt = console[indexPath.row]
            let attributedString = NSMutableAttributedString(string: "\(txt.name) - \(txt.date)")
            attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0), range: NSMakeRange(0, txt.name.characters.count))
            cell.textLabel?.attributedText = attributedString
            cell.detailTextLabel?.text = txt.id
        case 2:
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
            dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
            cell.textLabel?.text = dateFormatter.stringFromDate(rescheduleDates[indexPath.row])
            cell.detailTextLabel?.text = nil
        default: break
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch(indexPath.section) {
        case 2:
            return 44.0;
        default:
            return 70.0;
        }
    }

}
