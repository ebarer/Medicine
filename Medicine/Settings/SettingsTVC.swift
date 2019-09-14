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
import UserNotifications

class SettingsTVC: UITableViewController, MFMailComposeViewControllerDelegate {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let cdStack = (UIApplication.shared.delegate as! AppDelegate).stack
    let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine")!
    
    // MARK: - Outlets
    @IBOutlet var sortLabel: UILabel!
    @IBOutlet var snoozeLabel: UILabel!
    @IBOutlet var refillLabel: UILabel!
    @IBOutlet var versionString: UILabel!
    @IBOutlet var copyrightString: UILabel!

    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()

//        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        setLabels()
        
        // Set version string
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        versionString.text = "Medicine Manager \(version) (\(build))"
        
        // Set copyright string
        if let year = (Calendar(identifier: Calendar.Identifier.gregorian) as NSCalendar?)?.component(NSCalendar.Unit.year, from: Date()) {
            copyrightString.text = "\(year) © Elliot Barer"
        } else {
            copyrightString.text = "© Elliot Barer"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let index = tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: index, animated: animated)
        }
        
        setLabels()
        
        tableView.reloadData()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setLabels() {
        // Set sort label
        switch(defaults.integer(forKey: "sortOrder")) {
        case 0:
            sortLabel.text = "Manually"
        case 1:
            sortLabel.text = "Next Dosage"
        default: break
        }
        
        // Set snooze label
        var snoozeLength = defaults.integer(forKey: "snoozeLength")
        
        if snoozeLength == 0 {
            snoozeLength = 5
        }
        
        var snoozeString = "\(snoozeLength) minute"
        if (snoozeLength < 1 || snoozeLength >= 2) { snoozeString += "s" }
        snoozeLabel.text = snoozeString
        
        // Set refill label
        var refillTime = defaults.integer(forKey: "refillTime")
        
        if refillTime == 0 {
            refillTime = 3
        }
        
        var refillString = "\(refillTime) day"
        if (refillTime < 1 || refillTime >= 2) { refillString += "s" }
        refillLabel.text = refillString
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.cellForRow(at: indexPath)?.reuseIdentifier == "feedbackCell" {
            if (!sendFeedback()) {
                self.tableView.deselectRow(at: indexPath, animated: true)
            }
        }
        
        if tableView.cellForRow(at: indexPath)?.reuseIdentifier == "resetCell" {
            promptForAppReset()
        }
    }
    
    // MARK: - Helper methods
    func sendFeedback() -> Bool {
        if MFMailComposeViewController.canSendMail() {
            let mc = MFMailComposeViewController()
            mc.mailComposeDelegate = self
            mc.setToRecipients(["feedback@ebarer.com"])
            mc.setSubject("Feedback for Medicine Manager")
            
            DispatchQueue.global(qos: .userInitiated).async {
                if let deviceInfo = self.generateDeviceInfo().data(using: .utf8, allowLossyConversion: false) {
                    DispatchQueue.main.async {
                        mc.addAttachmentData(deviceInfo, mimeType: "text/plain", fileName: "device_information.txt")
                    }
                }
            }
            
            self.present(mc, animated: true, completion: nil)
            return true
        }
        
        NSLog("Settings", "Unable to send feedback: user unable to send mail.")
        return false
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func promptForAppReset() {
        let deleteAlert = UIAlertController(title: "Reset Data and Settings?", message: "This will permanently delete all medication, history, and preferences.", preferredStyle: UIAlertController.Style.alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: {(action) -> Void in
            if let selectedIndex = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRow(at: selectedIndex, animated: true)
            }
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Reset Data and Settings", style: .destructive, handler: {(action) -> Void in
            self.resetApp()
        }))
        
        deleteAlert.view.tintColor = UIColor.alertTint
        self.present(deleteAlert, animated: true, completion: nil)
    }
    
    func resetApp() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Medicine.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeCount
        
        if let index = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: index, animated: false)
        }
        
        do {
            let deleteCount = try cdStack.context.execute(batchDeleteRequest) as! NSBatchDeleteResult
            NSLog("ResetApp", "Deleted \(deleteCount) objects")
            cdStack.context.reset()

            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
            
            // Clear scheduled notifications
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            
            // Reset preferences
            defaults.set(SortOrder.nextDosage.rawValue, forKey: "sortOrder")
            defaults.set(5, forKey: "snoozeLength")
            defaults.set(3, forKey: "refillTime")
            defaults.set([], forKey: "todayData")
            defaults.synchronize()
            
            // Show reset confirmation
            let confirmationAlert = UIAlertController(title: "Reset Complete", message: "All medication, history, and preferences have been reset.", preferredStyle: UIAlertController.Style.alert)
            
            confirmationAlert.addAction(UIAlertAction(title: "Done", style: .default, handler: {(action) -> Void in
                self.dismiss(animated: true, completion: nil)
            }))

            confirmationAlert.view.tintColor = UIColor.alertTint
            self.present(confirmationAlert, animated: true, completion: nil)
        } catch {
            let updateError = error as NSError
            NSLog("ResetApp", "Error attempting to reset app: \(updateError), \(updateError.userInfo)")
        }
    }
    
    func generateDeviceInfo() -> String {
        let device = UIDevice.current
        let dictionary = Bundle.main.infoDictionary!
        let name = dictionary["CFBundleName"] as! String
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        
        var deviceInfo = "App Information:\r"
        deviceInfo += "App Name: \(name)\r"
        deviceInfo += "App Version: \(version) (\(build))\r\r"

        deviceInfo += "Device Information:\r"
        deviceInfo += "Device: \(deviceName())\r"
        deviceInfo += "iOS Version: \(device.systemVersion)\r"
        deviceInfo += "Timezone: \(TimeZone.autoupdatingCurrent.identifier) (\(NSTimeZone.local.abbreviation()!))\r\r"
        
        deviceInfo += "Obfuscated Medicine Information:\r"
        
        let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
        if let medication = try? cdStack.context.fetch(request) {
            for (index, med) in medication.enumerated() {
                if let score = med.adherenceScore() {
                    deviceInfo += "Medicine \(index) (\(score)%): "
                } else {
                    deviceInfo += "Medicine \(index) (-%): "
                }
                
                deviceInfo += "\(med.dosage.removeTrailingZero()) \(med.dosageUnit.units(med.dosage)), every " +
                              "\(med.interval.removeTrailingZero()) \(med.intervalUnit.units(med.interval)) "
                
                if med.refillHistory?.count == 0 {
                    deviceInfo += "(No refill history)"
                } else {
                    deviceInfo += "(\(med.prescriptionCount.removeTrailingZero()) \(med.dosageUnit.units(med.prescriptionCount)) remaining)\r"
                }
            }
        }
        
        return deviceInfo
    }
    
    func deviceName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return identifier
    }
    
    // MARK: - Navigation
    @IBAction func dismissSettings(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    // Used to dismiss popover selections
    @IBAction func settingsUnwind(_ unwindSegue: UIStoryboardSegue) {}

}
