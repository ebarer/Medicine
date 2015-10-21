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
var rescheduleDates = [NSDate]()


class MainTBC: UITabBarController, UITabBarControllerDelegate {
    
    // MARK: - Helper variables
    
    let defaults = NSUserDefaults(suiteName: "group.com.ebarer.Medicine")!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var moc: NSManagedObjectContext!
    var launchedShortcutItem: [NSObject: AnyObject]?
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
        // Set mananged object context
        moc = appDelegate.managedObjectContext
        
        // Set tab bar controller
        tabBar.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        
        // Add observeres for notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "rescheduleNotifications:", name: "rescheduleNotifications", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "takeMedicationNotification:", name: "takeDoseNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "snoozeReminderNotification:", name: "snoozeReminderNotification", object: nil)
        
        loadMedication()
        
        if let dates = defaults.objectForKey("rescheduleDates") {
            rescheduleDates = dates as! [NSDate]
            rescheduleDates.sortInPlace({$0.compare($1) == .OrderedDescending})
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        for vc in viewController.childViewControllers {
            if vc.isKindOfClass(SettingsTVC_Console) {
                let svc = vc as! SettingsTVC_Console
                svc.reloadView()
            }
        }
    }

    
    // MARK: - Observers
    
    func rescheduleNotifications(notification: NSNotification) {
        let app = UIApplication.sharedApplication()
        
        app.cancelAllLocalNotifications()
        
        for med in medication {
            med.scheduleNextNotification()
        }
        
        setDynamicShortcuts()
        NSNotificationCenter.defaultCenter().postNotificationName("refreshWidget", object: nil, userInfo: nil)
        
        rescheduleDates.insert(NSDate(), atIndex: 0)
        
        if rescheduleDates.count >= 5 {
            //rescheduleDates.removeAtIndex(5)
        }
        
        defaults.setObject(rescheduleDates, forKey: "rescheduleDates")
        defaults.synchronize()
    }
    
    func takeMedicationNotification(notification: NSNotification) {
        if let id = notification.userInfo!["id"] as? String {
            if let med = Medicine.getMedicine(arr: medication, id: id) {
                med.addDose(moc, date: NSDate())
                appDelegate.saveContext()
                
                setDynamicShortcuts()
                NSNotificationCenter.defaultCenter().postNotificationName("refreshMedication", object: nil, userInfo: nil)
            }
        }
    }
    
    func snoozeReminderNotification(notification: NSNotification) {
        if let id = notification.userInfo!["id"] as? String {
            if let med = Medicine.getMedicine(arr: medication, id: id) {
                med.snoozeNotification()
                appDelegate.saveContext()
                    
                setDynamicShortcuts()
                NSNotificationCenter.defaultCenter().postNotificationName("refreshMedication", object: nil, userInfo: nil)
            }
        }
    }
    
    
    // MARK: - Helper methods
    
    func loadMedication() {
        let request = NSFetchRequest(entityName:"Medicine")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        
        do {
            let fetchedResults = try moc.executeFetchRequest(request) as? [Medicine]
            
            if let results = fetchedResults {
                // Store results in medication array
                medication = results
                
                // Index results
                if #available(iOS 9.0, *) {                    
                    for med in medication  {
                        if let attributes = med.attributeSet {
                            let item = CSSearchableItem(uniqueIdentifier: med.medicineID, domainIdentifier: nil, attributeSet: attributes)
                            CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([item], completionHandler: nil)
                        }
                    }
                }
                    
                // Update homescreen shortcuts for force touch devices
                setDynamicShortcuts()
            }
        } catch {
            print("Could not fetch medication.")
        }
    }
    
    func setDynamicShortcuts() {
        if #available(iOS 9.0, *) {
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