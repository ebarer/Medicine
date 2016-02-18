//
//  SettingsTVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-21.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData
import MessageUI

class SettingsTVC: UITableViewController, MFMailComposeViewControllerDelegate {

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let defaults = NSUserDefaults(suiteName: "group.com.ebarer.Medicine")!
    
    
    // MARK: - Outlets
    
    @IBOutlet var sortLabel: UILabel!
    @IBOutlet var snoozeLabel: UILabel!
    @IBOutlet var refillLabel: UILabel!
    @IBOutlet var versionString: UILabel!
    @IBOutlet var copyrightString: UILabel!

    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setLabels()
        
        // Set version string
        let dictionary = NSBundle.mainBundle().infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        versionString.text = "Medicine Manager \(version) (\(build))"
        
        // Set copyright string
        if let year = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)?.component(NSCalendarUnit.Year, fromDate: NSDate()) {
            copyrightString.text = "\(year) © Elliot Barer"
        } else {
            copyrightString.text = "© Elliot Barer"
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let index = tableView.indexPathForSelectedRow {
            self.tableView.deselectRowAtIndexPath(index, animated: animated)
        }
        
        setLabels()
        
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setLabels() {
        // Set sort label
        switch(defaults.integerForKey("sortOrder")) {
        case 0:
            sortLabel.text = "Manually"
        case 1:
            sortLabel.text = "Next Dosage"
        default: break
        }
        
        // Set snooze label
        var snoozeLength = defaults.integerForKey("snoozeLength")
        
        if snoozeLength == 0 {
            snoozeLength = 5
        }
        
        var snoozeString = "\(snoozeLength) minute"
        if (snoozeLength < 1 || snoozeLength >= 2) { snoozeString += "s" }
        snoozeLabel.text = snoozeString
        
        // Set refill label
        var refillTime = defaults.integerForKey("refillTime")
        
        if refillTime == 0 {
            refillTime = 3
        }
        
        var refillString = "\(refillTime) day"
        if (refillTime < 1 || refillTime >= 2) { refillString += "s" }
        refillLabel.text = refillString
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            if let amount = refillLabel.text {
                return "You will be reminded to refill your medication when you have \(amount) worth of medication remaining."
            } else {
                return nil
            }
        case 1:
            return "Got a great idea, or seeing a pesky bug? Let us know!"
        default:
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.cellForRowAtIndexPath(indexPath)?.reuseIdentifier == "feedbackCell" {
            if MFMailComposeViewController.canSendMail() {
                if let deviceInfo = generateDeviceInfo().dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                    let mc = MFMailComposeViewController()
                    mc.mailComposeDelegate = self
                    mc.setToRecipients(["hello@medicinemanagerapp.com"])
                    mc.setSubject("Feedback for Medicine Manager")
                    mc.addAttachmentData(deviceInfo, mimeType: "text/plain", fileName: "device_information.txt")
                    
                    self.presentViewController(mc, animated: true, completion: nil)
                }
            } else {
                print("Can't send")
            }
        }
        
        if tableView.cellForRowAtIndexPath(indexPath)?.reuseIdentifier == "resetCell" {
            let deleteAlert = UIAlertController(title: "Reset Data and Settings?", message: "This will permanently delete all medication, history, and preferences.", preferredStyle: UIAlertControllerStyle.Alert)
            
            deleteAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {(action) -> Void in
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }))
            
            deleteAlert.addAction(UIAlertAction(title: "Reset Data and Settings", style: .Destructive, handler: {(action) -> Void in
                self.resetApp()
            }))
            
            deleteAlert.view.tintColor = UIColor.grayColor()
            self.presentViewController(deleteAlert, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: - Helper methods
    
    func resetApp() {
        let moc = appDelegate.managedObjectContext
        let request = NSFetchRequest(entityName:"Medicine")
        
        do {
            let fetchedResults = try moc.executeFetchRequest(request) as? [Medicine]
            
            // Delete all medications and corresponding history
            if let results = fetchedResults {
                for med in results {
                    moc.deleteObject(med)
                }
            }
            
            appDelegate.saveContext()
            
            medication.removeAll()
            
            // Clear scheduled notifications
            UIApplication.sharedApplication().cancelAllLocalNotifications()
            
            // Reset preferences
            defaults.setBool(true, forKey: "firstLaunch")
            defaults.setInteger(SortOrder.NextDosage.rawValue, forKey: "sortOrder")
            defaults.setInteger(5, forKey: "snoozeLength")
            defaults.setObject([], forKey: "todayData")
            defaults.synchronize()
            
            // Show reset confirmation
            let confirmationAlert = UIAlertController(title: "Reset Complete", message: "All medication, history, and preferences have been reset.", preferredStyle: UIAlertControllerStyle.Alert)
            
            confirmationAlert.addAction(UIAlertAction(title: "Restart", style: UIAlertActionStyle.Destructive, handler: {(action) -> Void in
                if let tbc = self.presentingViewController as? MainTBC {
                    if let splitView = tbc.viewControllers?.filter({$0.isKindOfClass(UISplitViewController)}).first as? UISplitViewController {
                        NSNotificationCenter.defaultCenter().postNotificationName("refreshView", object: nil)
                        NSNotificationCenter.defaultCenter().postNotificationName("refreshMain", object: nil)
                        
                        self.dismissViewControllerAnimated(false, completion: nil)
                        
                        let masterVC = splitView.viewControllers[0].childViewControllers[0] as! MainVC
                        masterVC.performSegueWithIdentifier("tutorial", sender: masterVC)
                    }
                }
            }))
            
            confirmationAlert.view.tintColor = UIColor.grayColor()
            self.presentViewController(confirmationAlert, animated: true, completion: nil)
            if let index = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRowAtIndexPath(index, animated: false)
            }
        } catch {
            print("Could not fetch medication.")
        }
    }
    
    func generateDeviceInfo() -> String {
        let device = UIDevice.currentDevice()
        let dictionary = NSBundle.mainBundle().infoDictionary!
        let name = dictionary["CFBundleName"] as! String
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        
        var deviceInfo = "App Information:\r"
        deviceInfo += "App Name: \(name)\r"
        deviceInfo += "App Version: \(version) (\(build))\r\r"

        deviceInfo += "Device Information:\r"
        deviceInfo += "Device: \(deviceName())\r"
        deviceInfo += "iOS Version: \(device.systemVersion)\r"
        deviceInfo += "Timezone: \(NSTimeZone.localTimeZone().name) (\(NSTimeZone.localTimeZone().abbreviation!))\r\r"
        
        deviceInfo += "Obfuscated Medicine Information:\r"
        
        for (index, med) in medication.enumerate() {
            if let score = med.adherenceScore() {
                deviceInfo += "Medicine \(index) (\(score)%): "
            } else {
                deviceInfo += "Medicine \(index) (-%): "
            }
            
            deviceInfo += "\(med.removeTrailingZero(med.dosage)) \(med.dosageUnit.units(med.dosage)), every " +
                          "\(med.removeTrailingZero(med.interval)) \(med.intervalUnit.units(med.interval)) "
            
            if med.refillHistory?.count == 0 {
                deviceInfo += "(No refill history)"
            } else {
                deviceInfo += "(\(med.removeTrailingZero(med.prescriptionCount)) \(med.dosageUnit.units(med.prescriptionCount)) remaining)\r"
            }
        }
        
        return deviceInfo
    }
    
    func deviceName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 where value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return identifier
    }
    
    
    // MARK: - Navigation
    
    @IBAction func dismissSettings(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

}
