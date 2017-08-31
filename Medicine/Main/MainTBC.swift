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

class MainTBC: UITabBarController, UITabBarControllerDelegate {
    
    // MARK: - Helper variables
    let cdStack = (UIApplication.shared.delegate as! AppDelegate).stack
    let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine")!
    
    var launchedShortcutItem: [AnyHashable: Any]?
    
    var selectedVC: UIViewController? = nil
    
    // MARK: - Load medication
    func loadMedication() {
        let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        if let medication = try? cdStack.context.fetch(request) {
            indexMedication()
            setDynamicShortcuts(forMedication: medication)
        }
    }
    
    
    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
        // Set tab bar controller
        tabBar.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
       
        loadMedication()
        
        // Add observeres for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(doseNotification(_:)), name: NSNotification.Name(rawValue: "doseNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refillNotification(_:)), name: NSNotification.Name(rawValue: "refillNotification"), object: nil)
        
        // Add observers for notification actions
        NotificationCenter.default.addObserver(self, selector: #selector(takeDoseAction(_:)), name: NSNotification.Name(rawValue: "takeDoseAction"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(snoozeReminderAction(_:)), name: NSNotification.Name(rawValue: "snoozeReminderAction"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refillAction(_:)), name: NSNotification.Name(rawValue: "refillAction"), object: nil)
        
        // Add observer for scheduling notifications and updating app badge count
        NotificationCenter.default.addObserver(self, selector: #selector(rescheduleNotifications(_:)), name: NSNotification.Name(rawValue: "rescheduleNotifications"), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Tab delegate
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewController == selectedVC {
            if viewController.isKind(of: UISplitViewController.self) {
                let navVC = (viewController as! UISplitViewController).childViewControllers[0] as! UINavigationController
                navVC.popToRootViewController(animated: true)
            }
        }
        
        selectedVC = viewController
    }

    
    // MARK: - Notification observers
    @objc func doseNotification(_ notification: Notification) {
        if let id = notification.userInfo!["id"] as? String {
            let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
            request.predicate = NSPredicate(format: "medicineID == %@", argumentArray: [id])
            if let med = (try? cdStack.context.fetch(request))?.first {
                print("doseNotification triggered for \(med.name ?? "unknown medicine")")
                
                let message = String(format:"Time to take %g %@ of %@", med.dosage, med.dosageUnit.units(med.dosage), med.name!)
                
                let alert = UIAlertController(title: "Take \(med.name!)", message: message, preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Take Dose", style:  UIAlertActionStyle.destructive, handler: {(action) -> Void in
                    self.performSegue(withIdentifier: "addDose", sender: med)
                }))
                
                if med.lastDose != nil {
                    alert.addAction(UIAlertAction(title: "Snooze", style: UIAlertActionStyle.default, handler: {(action) -> Void in
                        med.snoozeNotification()
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
                    }))
                }
                
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: {(action) -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
                }))
                
                alert.view.tintColor = UIColor.gray
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @objc func refillNotification(_ notification: Notification) {
        if let id = notification.userInfo!["id"] as? String {
            let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
            request.predicate = NSPredicate(format: "medicineID == %@", argumentArray: [id])
            if let med = (try? cdStack.context.fetch(request))?.first {
                print("refillNotification triggered for \(med.name ?? "unknown medicine")")
                
                var message = "You are running low on \(med.name!) and should refill soon."
                
                if med.prescriptionCount < med.dosage {
                    message = "You don't have enough \(med.name!) to take your next dose."
                } else if let count = med.refillDaysRemaining(), med.prescriptionCount > 0 && count > 0 {
                    message = "You currently have enough \(med.name!) for about \(count) \(count == 1 ? "day" : "days") and should refill soon."
                }
                
                let alert = UIAlertController(title: "Reminder to Refill \(med.name!)", message: message, preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Refill", style:  UIAlertActionStyle.destructive, handler: {(action) -> Void in
                    self.performSegue(withIdentifier: "refillPrescription", sender: med)
                }))
                
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: nil))
                
                alert.view.tintColor = UIColor.gray
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    
    // MARK: - Action observers
    @objc func takeDoseAction(_ notification: Notification) {
        NSLog("takeDoseAction received", [])
        if let id = notification.userInfo!["id"] as? String {
            let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
            request.predicate = NSPredicate(format: "medicineID == %@", argumentArray: [id])
            if let medication = try? cdStack.context.fetch(request), let med = medication.first {
                let dose = Dose(insertInto: cdStack.context)
                dose.date = Date()
                dose.dosage = med.dosage
                dose.dosageUnitInt = med.dosageUnitInt
                med.addDose(dose)
                
                // Check if medication needs to be refilled
                let refillTime = defaults.integer(forKey: "refillTime")
                if med.needsRefill(limit: refillTime) {
                    med.sendRefillNotification()
                }
                
                cdStack.save()
                NSLog("takeDoseAction performed", [])

                setDynamicShortcuts(forMedication: medication)
                updateBadgeCount()
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
            }
        }
    }
    
    @objc func snoozeReminderAction(_ notification: Notification) {
        NSLog("snoozeReminderAction received", [])
        if let id = notification.userInfo!["id"] as? String {
            let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
            request.predicate = NSPredicate(format: "medicineID == %@", argumentArray: [id])
            if let medication = try? cdStack.context.fetch(request), let med = medication.first {
                med.snoozeNotification()
                setDynamicShortcuts(forMedication: medication)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
                NSLog("snoozeReminderAction performed for %@", [med.name!])
            }
        }
    }
    
    @objc func refillAction(_ notification: Notification) {
        NSLog("refillAction received", [])
        if let id = notification.userInfo!["id"] as? String {
            let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
            request.predicate = NSPredicate(format: "medicineID == %@", argumentArray: [id])
            if let med = (try? cdStack.context.fetch(request))?.first {
                performSegue(withIdentifier: "refillPrescription", sender: med)
                NSLog("refillAction performed for %@", [med.name!])
            }
        }
    }
    
    
    // MARK: - Other observers
    @objc func rescheduleNotifications(_ notification: Notification) {        
        // Reschedule notifications
        let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        if let medication = try? cdStack.context.fetch(request) {
            for med in medication {
                med.scheduleNextNotification()
            }
        
            setDynamicShortcuts(forMedication: medication)
            updateBadgeCount()
        }
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addDose" {
            if let vc = segue.destination.childViewControllers[0] as? AddDoseTVC {
                if let med = sender as? Medicine {
                    vc.med = med
                }
            }
        }
        
        if segue.identifier == "refillPrescription" {
            if let vc = segue.destination.childViewControllers[0] as? AddRefillTVC {
                if let med = sender as? Medicine {
                    vc.med = med
                }
            }
        }
    }
    
    
    // MARK: - Helper methods
    // Update homescreen shortcuts for force touch devices
    func setDynamicShortcuts(forMedication medication: [Medicine]) {
        let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
        request.predicate = NSPredicate(format: "reminderEnabled == true", argumentArray: [])
        request.sortDescriptors = [NSSortDescriptor(key: "dateNextDose", ascending: true)]
        if let med = (try? cdStack.context.fetch(request))?.first {
            // Set shortcut for overdue item
            if med.isOverdue().flag {
                let shortcutItem = UIApplicationShortcutItem(type: "com.ebarer.Medicine.overdue",
                                                             localizedTitle: "Overdue",
                                                             localizedSubtitle: "\(med.name!)",
                                                             icon: UIApplicationShortcutIcon(templateImageName: "OverdueGlyph"),
                                                             userInfo: ["action" : "takeDose", "medID" : med.medicineID])
                
                UIApplication.shared.shortcutItems = [shortcutItem]
                return
            } else if let date = med.nextDose {
                let dose = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
                let subtitle = "\(Medicine.dateString(date)): \(dose) of \(med.name!)"
                
                let shortcutItem = UIApplicationShortcutItem(type: "com.ebarer.Medicine.takeDose",
                                                             localizedTitle: "Take Next Dose",
                                                             localizedSubtitle: subtitle,
                                                             icon: UIApplicationShortcutIcon(templateImageName: "NextDoseGlyph"),
                                                             userInfo: ["action" : "takeDose", "medID" : med.medicineID])
                
                UIApplication.shared.shortcutItems = [shortcutItem]
                return
            }
        }
        
        UIApplication.shared.shortcutItems = []
    }

    func updateBadgeCount() {
        let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        if let medication = try? cdStack.context.fetch(request) {
            let overdueCount = medication.filter({$0.isOverdue().flag}).count
            UIApplication.shared.applicationIconBadgeNumber = overdueCount
        }
    }
    
    func indexMedication() {
        // Update spotlight index
        let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        if let medication = try? cdStack.context.fetch(request) {
            for med in medication  {
                if let attributes = med.attributeSet {
                    let item = CSSearchableItem(uniqueIdentifier: med.medicineID, domainIdentifier: nil, attributeSet: attributes)
                    CSSearchableIndex.default().indexSearchableItems([item], completionHandler: nil)
                }
            }
        }
    }
    
}

extension UITabBarController {
    
    func setTabBarVisible(_ visible: Bool, animated: Bool) {
        if tabBarIsVisible() != visible {
            // Determine frame calculation
            let frame = self.tabBar.frame
            let height = frame.size.height
            let offsetY = (visible ? -height : height)

            UIView.animate(withDuration: animated ? 0.3 : 0.0, animations: {
                // Change frame of TabBar
                self.tabBar.frame = frame.offsetBy(dx: 0, dy: offsetY)
                
                // Change frame of UITabBarController
                self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height + offsetY)
                self.view.setNeedsDisplay()
                self.view.layoutIfNeeded()
            }) 
        }
    }
    
    func tabBarIsVisible() -> Bool {
        return self.tabBar.frame.origin.y < self.view.frame.maxY
    }
    
}
