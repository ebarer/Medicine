//
//  MainTBC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-21.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData
import CoreSpotlight
import MobileCoreServices

// Global medication array
var medication = [Medicine]()

class MainTBC: UITabBarController, UITabBarControllerDelegate {
    
    
    // MARK: - Helper variables
    let defaults = NSUserDefaults(suiteName: "group.com.ebarer.Medicine")!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext!
    var launchedShortcutItem: [NSObject: AnyObject]?
    
    var selectedVC: UIViewController? = nil
    
    
    // MARK: - Load medication
    func loadMedication() {
        let request = NSFetchRequest(entityName:"Medicine")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        
        do {
            let fetchedResults = try moc.executeFetchRequest(request) as? [Medicine]
            
            if let results = fetchedResults {
                // Store results in medication array
                medication = results
                
                // If selected, sort by next dosage
                if defaults.integerForKey("sortOrder") == SortOrder.NextDosage.rawValue {
                    medication.sortInPlace(Medicine.sortByNextDose)
                }
                
                indexMedication()
                setDynamicShortcuts()
            }
        } catch {
            print("Could not fetch medication.")
        }
    }
    
    
    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
        // Set mananged object context
        moc = appDelegate.managedObjectContext
        
        // Set tab bar controller
        tabBar.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
       
        loadMedication()
        
        // Add observeres for notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "doseNotification:", name: "doseNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refillNotification:", name: "refillNotification", object: nil)
        
        // Add observers for notification actions
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "takeDoseAction:", name: "takeDoseAction", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "snoozeReminderAction:", name: "snoozeReminderAction", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refillAction:", name: "refillAction", object: nil)
        
        // Add observer for scheduling notifications and updating app badge count
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "rescheduleNotifications:", name: "rescheduleNotifications", object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Tab delegate
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if viewController == selectedVC {
            if viewController.isKindOfClass(UISplitViewController) {
                let navVC = (viewController as! UISplitViewController).childViewControllers[0] as! UINavigationController
                navVC.popToRootViewControllerAnimated(true)
            }
        }
        
        selectedVC = viewController
    }

    
    // MARK: - Notification observers
    func doseNotification(notification: NSNotification) {
        if let id = notification.userInfo!["id"] as? String {
            let medQuery = Medicine.getMedicine(arr: medication, id: id)
            if let med = medQuery {
                print("doseNotification triggered for \(med.name)")
                
                let message = String(format:"Time to take %g %@ of %@", med.dosage, med.dosageUnit.units(med.dosage), med.name!)
                
                let alert = UIAlertController(title: "Take \(med.name!)", message: message, preferredStyle: .Alert)
                
                alert.addAction(UIAlertAction(title: "Take Dose", style:  UIAlertActionStyle.Destructive, handler: {(action) -> Void in
                    self.performSegueWithIdentifier("addDose", sender: med)
                }))
                
                if med.lastDose != nil {
                    alert.addAction(UIAlertAction(title: "Snooze", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
                        if let id = notification.userInfo!["id"] as? String {
                            if let med = Medicine.getMedicine(arr: medication, id: id) {
                                med.snoozeNotification()
                                NSNotificationCenter.defaultCenter().postNotificationName("refreshView", object: nil)
                                NSNotificationCenter.defaultCenter().postNotificationName("refreshMain", object: nil)
                            }
                        }
                    }))
                }
                
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Cancel, handler: {(action) -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName("refreshView", object: nil)
                    NSNotificationCenter.defaultCenter().postNotificationName("refreshMain", object: nil)
                }))
                
                alert.view.tintColor = UIColor.grayColor()
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    func refillNotification(notification: NSNotification) {
        if let id = notification.userInfo!["id"] as? String {
            let medQuery = Medicine.getMedicine(arr: medication, id: id)
            if let med = medQuery {
                print("refillNotification triggered for \(med.name)")
                
                var message = "You are running low on \(med.name!) and should refill soon."
                
                if med.prescriptionCount < med.dosage {
                    message = "You don't have enough \(med.name!) to take your next dose."
                } else if let count = med.refillDaysRemaining() where med.prescriptionCount > 0 && count > 0 {
                    message = "You currently have enough \(med.name!) for about \(count) \(count == 1 ? "day" : "days") and should refill soon."
                }
                
                let alert = UIAlertController(title: "Reminder to Refill \(med.name!)", message: message, preferredStyle: .Alert)
                
                alert.addAction(UIAlertAction(title: "Refill", style:  UIAlertActionStyle.Destructive, handler: {(action) -> Void in
                    self.performSegueWithIdentifier("refillPrescription", sender: med)
                }))
                
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Cancel, handler: nil))
                
                alert.view.tintColor = UIColor.grayColor()
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    
    // MARK: - Action observers
    func takeDoseAction(notification: NSNotification) {
        NSLog("takeDoseAction received", [])
        if let id = notification.userInfo!["id"] as? String {
            if let med = Medicine.getMedicine(arr: medication, id: id) {
                let entity = NSEntityDescription.entityForName("Dose", inManagedObjectContext: moc)
                let dose = Dose(entity: entity!, insertIntoManagedObjectContext: moc)
                
                dose.medicine = med
                dose.date = NSDate()
                dose.dosage = med.dosage
                dose.dosageUnitInt = med.dosageUnitInt
                
                med.addDose(dose)
                
                // Check if medication needs to be refilled
                let refillTime = defaults.integerForKey("refillTime")
                if med.needsRefill(limit: refillTime) {
                    med.sendRefillNotification()
                }
                
                appDelegate.saveContext()
                
                setDynamicShortcuts()
                NSNotificationCenter.defaultCenter().postNotificationName("refreshView", object: nil)
                NSNotificationCenter.defaultCenter().postNotificationName("refreshMain", object: nil)
                NSLog("takeDoseAction performed", [])
            }
        }
    }
    
    func snoozeReminderAction(notification: NSNotification) {
        NSLog("snoozeReminderAction received", [])
        if let id = notification.userInfo!["id"] as? String {
            if let med = Medicine.getMedicine(arr: medication, id: id) {
                med.snoozeNotification()
                setDynamicShortcuts()
                NSNotificationCenter.defaultCenter().postNotificationName("refreshView", object: nil)
                NSNotificationCenter.defaultCenter().postNotificationName("refreshMain", object: nil)
                NSLog("snoozeReminderAction performed", [])
            }
        }
    }
    
    func refillAction(notification: NSNotification) {
        NSLog("refillAction received", [])
        if let id = notification.userInfo!["id"] as? String {
            if let med = Medicine.getMedicine(arr: medication, id: id) {
                performSegueWithIdentifier("refillPrescription", sender: med)
                NSLog("refillAction performed", [])
            }
        }
    }
    
    
    // MARK: - Other observers
    func rescheduleNotifications(notification: NSNotification) {        
        // Reschedule notifications
        for med in medication {
            med.scheduleNextNotification()
        }
        
        // Update shortcuts
        setDynamicShortcuts()
        
        // Update badge count
        let overdueCount = medication.filter({$0.isOverdue().flag}).count
        UIApplication.sharedApplication().applicationIconBadgeNumber = overdueCount
    }
    
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addDose" {
            if let vc = segue.destinationViewController.childViewControllers[0] as? AddDoseTVC {
                if let med = sender as? Medicine {
                    vc.med = med
                }
            }
        }
        
        if segue.identifier == "refillPrescription" {
            if let vc = segue.destinationViewController.childViewControllers[0] as? AddRefillTVC {
                if let med = sender as? Medicine {
                    vc.med = med
                }
            }
        }
    }
    
    
    // MARK: - Helper methods
    func setDynamicShortcuts() {
        // Update homescreen shortcuts for force touch devices
        let overdueItems = medication.filter({$0.isOverdue().flag})
        if overdueItems.count > 0  {
            var text = "Overdue Dose"
            var subtitle: String? = nil
            var userInfo = [String:String]()
            
            // Pluralize string if multiple overdue doses
            if overdueItems.count > 1 {
                text += "s"
            }
                // Otherwise set subtitle to overdue med
            else {
                let med = overdueItems.first!
                subtitle = med.name!
                userInfo["action"] = "takeDose"
                userInfo["medID"] = med.medicineID
            }
            
            let shortcutItem = UIApplicationShortcutItem(type: "com.ebarer.Medicine.overdue",
                localizedTitle: text, localizedSubtitle: subtitle,
                icon: UIApplicationShortcutIcon(templateImageName: "OverdueGlyph"),
                userInfo: userInfo)
            
            UIApplication.sharedApplication().shortcutItems = [shortcutItem]
            return
        } else if let nextDose = UIApplication.sharedApplication().scheduledLocalNotifications?.first {
            if let id = nextDose.userInfo?["id"] {
                guard let med = Medicine.getMedicine(arr: medication, id: id as! String) else { return }
                let dose = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
                let date = nextDose.fireDate
                let subtitle = "\(Medicine.dateString(date)): \(dose) of \(med.name!)"
                
                let shortcutItem = UIApplicationShortcutItem(type: "com.ebarer.Medicine.takeDose",
                    localizedTitle: "Take Next Dose", localizedSubtitle: subtitle,
                    icon: UIApplicationShortcutIcon(templateImageName: "NextDoseGlyph"),
                    userInfo: ["action":"takeDose", "medID":med.medicineID])
                
                UIApplication.sharedApplication().shortcutItems = [shortcutItem]
                return
            }
        }
        
        UIApplication.sharedApplication().shortcutItems = []
    }

    func indexMedication() {
        // Update spotlight index
        for med in medication  {
            if let attributes = med.attributeSet {
                let item = CSSearchableItem(uniqueIdentifier: med.medicineID, domainIdentifier: nil, attributeSet: attributes)
                CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([item], completionHandler: nil)
            }
        }
    }
    
}

extension UITabBarController {
    
    func setTabBarVisible(visible: Bool, animated: Bool) {
        if tabBarIsVisible() != visible {
            // Determine frame calculation
            let frame = self.tabBar.frame
            let height = frame.size.height
            let offsetY = (visible ? -height : height)

            UIView.animateWithDuration(animated ? 0.3 : 0.0) {
                // Change frame of TabBar
                self.tabBar.frame = CGRectOffset(frame, 0, offsetY)
                
                // Change frame of UITabBarController
                self.view.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height + offsetY)
                self.view.setNeedsDisplay()
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func tabBarIsVisible() -> Bool {
        return self.tabBar.frame.origin.y < CGRectGetMaxY(self.view.frame)
    }
    
}