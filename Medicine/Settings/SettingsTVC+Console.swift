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

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    let dateFormatter = NSDateFormatter()

    let notifications = UIApplication.sharedApplication().scheduledLocalNotifications!
    var medication = [Medicine]()
    var console = [(name: String, date: String, id: String)]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load medications
        let moc = appDelegate.managedObjectContext
        let request = NSFetchRequest(entityName:"Medicine")
        
        do {
            let fetchedResults = try moc.executeFetchRequest(request) as? [Medicine]
            
            if let results = fetchedResults {
                medication = results
                
                if notifications.count != 0 {
                    for (_, notification) in notifications.enumerate() {
                        if let id = notification.userInfo?["id"] {
                            if let med = Medicine.getMedicine(arr: medication, id: id as! String) {
                                dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
                                dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
                                console.append((med.name!, dateFormatter.stringFromDate(notification.fireDate!), id as! String))
                            }
                        }
                    }
                }
            }
        } catch {
            print("Could not fetch medication.")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return console.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Scheduled Notifications"
        }
        
        return nil
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("consoleCell", forIndexPath: indexPath)
        let txt = console[indexPath.row]

        let attributedString = NSMutableAttributedString(string: "\(txt.name) \t\t \(txt.date)")
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 251/255, green: 0/255, blue: 44/255, alpha: 1.0), range: NSMakeRange(0, txt.name.characters.count))
        
        
        cell.textLabel?.attributedText = attributedString
        cell.detailTextLabel?.text = txt.id

        return cell
    }
    
    
    // MARK: - Table view delegate

}
