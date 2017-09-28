//
//  AppDelegate.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-27.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData
import CoreSpotlight
import StoreKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    let stack = CoreDataStack()!
    var backgroundTask: UIBackgroundTaskIdentifier?

    // MARK: - Application methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.statusBarStyle = .lightContent
        
        // Handle views on startup
        if let tbc = self.window!.rootViewController as? UITabBarController {
            if let splitView = tbc.viewControllers?.filter({$0.isKind(of: UISplitViewController.self)}).first as? UISplitViewController {
                
                // Configure split view on startup
                splitView.delegate = self
                
                let dim = min(splitView.view.bounds.width, splitView.view.bounds.height)
                splitView.minimumPrimaryColumnWidth = dim / 2
                splitView.maximumPrimaryColumnWidth = dim / 2
                splitView.preferredPrimaryColumnWidthFraction = 0.5

                let detailNVC = splitView.viewControllers[1] as! UINavigationController
                detailNVC.topViewController?.navigationItem.leftBarButtonItem = splitView.displayModeButtonItem
                
                // Add IAP observer to MainVC
                let masterVC = splitView.viewControllers[0].childViewControllers[0] as! MainVC
                SKPaymentQueue.default().add(masterVC)
                NSLog("IAP transaction observer added")
            }
        }
        
        setUserDefaults()
        
        // Attach delegate for notifications and reschedule notifications
        configureNotificationAuthorization()
        rescheduleNotifications()
        
        // Add observer for day change
        NotificationCenter.default.addObserver(self, selector: #selector(rescheduleNotifications(completionHandler:)), name: .NSCalendarDayChanged, object: nil)
        
        // Setup background fetch to reload reschedule notifications
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        backgroundTask = application.beginBackgroundTask(withName: "rescheduleNotifications", expirationHandler: nil)
        
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
        rescheduleNotifications()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        self.stack.save()

        rescheduleNotifications()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        self.stack.save()
        
        // Remove IAP observers
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKind(of: UINavigationController.self)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKind(of: MainVC.self)}).first {
                SKPaymentQueue.default().remove(vc as! MainVC)
            }
        }

        rescheduleNotifications()
    }
}

// MARK: - Background Fetch: Notification scheduling
extension AppDelegate {
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NSLog("Background fetch:")
        
        rescheduleNotifications {
            NSLog("Completed background fetch.")
            completionHandler(UIBackgroundFetchResult.newData)
        }
    }
    
    @objc func rescheduleNotifications(completionHandler: (() -> Void)? = nil) {
        NSLog("Rescheduling notifications")
        
        let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
        request.predicate = NSPredicate(format: "reminderEnabled == true", [])
        if let medication = try? stack.context.fetch(request) {
            for med in medication {
                med.scheduleNextNotification()
            }
        }
        
        DispatchQueue.main.async {
            self.logNotifications()
            self.setDynamicShortcuts()
            self.updateBadgeCount()
            self.indexMedication()
        }
        
        if let completion = completionHandler {
            completion()
        }
    }
    
    func logNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            for request in requests {
                if let dateComponents = (request.trigger as? UNCalendarNotificationTrigger)?.dateComponents {
                    guard let date = Calendar.current.date(from: dateComponents) else {
                        continue
                    }
                    let logMessage = "Notification: \(request.identifier), Date: \(date)"
                    NSLog(logMessage)
                }
            }
        }
    }
    
    func updateBadgeCount() {
        let count = Medicine.overdueCount()
        UIApplication.shared.applicationIconBadgeNumber = count
        NSLog("Updating app badge count to: \(count)")
    }
}

// MARK: - Application shortcut stack
extension AppDelegate {
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem))
    }
    
    @discardableResult func handleShortcut(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        if let tbc = self.window!.rootViewController as? UITabBarController {
            if let splitView = tbc.viewControllers?.filter({$0.isKind(of: UISplitViewController.self)}).first as? UISplitViewController {
                let mainVC = splitView.viewControllers[0].childViewControllers[0] as! MainVC
                mainVC.handleShortcut(shortcutItem: shortcutItem)
            }
        }
        
        return false
    }

    func setDynamicShortcuts() {
        NSLog("Updating dynamic shortcuts")
        
        let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
        request.predicate = NSPredicate(format: "reminderEnabled == true", argumentArray: [])
        request.fetchLimit = 3
        request.sortDescriptors = [
            NSSortDescriptor(key: "hasNextDose", ascending: false),
            NSSortDescriptor(key: "dateNextDose", ascending: true),
            NSSortDescriptor(key: "dateLastDose", ascending: false)
        ]
        
        var shortcutItems = [UIApplicationShortcutItem]()
        
        if let medication = try? stack.context.fetch(request) {
            for med in medication {
                // Set shortcut for overdue item
                if med.isOverdue().flag {
                    let dose = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
                    let subtitle = "\(dose) — Overdue"
                    
                    let shortcutItem = UIApplicationShortcutItem(type: "com.ebarer.Medicine.overdue",
                                                                 localizedTitle: "Take \(med.name!)",
                                                                 localizedSubtitle: subtitle,
                        icon: UIApplicationShortcutIcon(templateImageName: "OverdueGlyph"),
                        userInfo: ["action" : "takeDose", "medID" : med.medicineID])
                    
                    shortcutItems.append(shortcutItem)
                } else if let date = med.nextDose {
                    let dose = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
                    let subtitle = "\(dose) — \(Medicine.dateString(date))"
                    
                    let shortcutItem = UIApplicationShortcutItem(type: "com.ebarer.Medicine.takeDose",
                                                                 localizedTitle: "Take \(med.name!)",
                                                                 localizedSubtitle: subtitle,
                                                                 icon: UIApplicationShortcutIcon(templateImageName: "NextDoseGlyph"),
                                                                 userInfo: ["action" : "takeDose", "medID" : med.medicineID])
                    
                    shortcutItems.append(shortcutItem)
                } else {
                    let dose = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
                    let subtitle = "\(dose) — As needed"
                    
                    let shortcutItem = UIApplicationShortcutItem(type: "com.ebarer.Medicine.takeDose",
                                                                 localizedTitle: "Take \(med.name!)",
                                                                 localizedSubtitle: subtitle,
                                                                 icon: UIApplicationShortcutIcon(templateImageName: "NextDoseGlyph"),
                                                                 userInfo: ["action" : "takeDose", "medID" : med.medicineID])
                    
                    shortcutItems.append(shortcutItem)
                }
            }
        }
        
        UIApplication.shared.shortcutItems = shortcutItems
    }
}

// MARK: - Core Spotlight
extension AppDelegate {
    func indexMedication() {
        NSLog("Indexing medication for CoreSpotlight")
        
        // Update spotlight index
        let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        if let medication = try? stack.context.fetch(request) {
            for med in medication  {
                if let attributes = med.attributeSet {
                    let item = CSSearchableItem(uniqueIdentifier: med.medicineID, domainIdentifier: nil, attributeSet: attributes)
                    CSSearchableIndex.default().indexSearchableItems([item], completionHandler: nil)
                }
            }
        }
    }
    
    func removeIndex(med: Medicine) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [med.medicineID], completionHandler: nil)
    }
}

// MARK: - Split view
extension AppDelegate: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? MedicineDetailsTVC else { return false }
        
        // If detail view is empty, return true to dismiss on launch
        if topAsDetailController.med == nil {
            return true
        }
        
        return false
    }
    
    func splitViewController(_ svc: UISplitViewController, shouldHide vc: UIViewController, in orientation: UIInterfaceOrientation) -> Bool {
        return false
    }
}

// MARK: - Notifications
extension AppDelegate {
    func checkNotificationAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .notDetermined:
                NSLog("Authorization status: UNDETERMINED")
            case .authorized:
                NSLog("Authorization status: AUTHORIZED")
            case .denied:
                NSLog("Authorization status: DENIED")
            }
        }
    }
    
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {(accepted, error) in
            if accepted {
                self.configureNotificationAuthorization()
            } else {
                NSLog("Notification access denied.", [])
            }
        }
    }
    
    func configureNotificationAuthorization() {
        NSLog("Notifications configured.")
        UNUserNotificationCenter.current().setNotificationCategories(self.notificationCategories)
        UNUserNotificationCenter.current().delegate = self
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let actionIdentifier = response.actionIdentifier
        let notificationIdentifier = response.notification.request.identifier
        let category = response.notification.request.content.categoryIdentifier
        let userInfo = response.notification.request.content.userInfo

        NSLog("Notification received (background): \(notificationIdentifier), \(actionIdentifier), \(userInfo)")
        
        if actionIdentifier == "takeDose" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "takeDoseAction"), object: nil, userInfo: userInfo)
        }
        
        else if actionIdentifier == "snoozeReminder" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "snoozeReminderAction"), object: nil, userInfo: userInfo)
        }
        
        else if actionIdentifier == "refillMed" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refillAction"), object: nil, userInfo: userInfo)
        }
        
        else if actionIdentifier == UNNotificationDefaultActionIdentifier {
            if category == "Dose Reminder" || category == "Dose Reminder - No Snooze" {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "doseNotification"), object: nil, userInfo: userInfo)
            }
            
            if category == "Refill Reminder" {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refillNotification"), object: nil, userInfo: userInfo)
            }
        }
        
        else if actionIdentifier == UNNotificationDismissActionIdentifier {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "rescheduleNotifications"), object: nil, userInfo: userInfo)
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let identifier = notification.request.identifier
        let category = notification.request.content.categoryIdentifier
        let userInfo = notification.request.content.userInfo

        NSLog("Notification received (foreground): \(identifier), \(category), \(userInfo)")
        
        if category == "Dose Reminder" || category == "Dose Reminder - No Snooze" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "doseNotification"), object: nil, userInfo: userInfo)
        }
        
        if category == "Refill Reminder" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refillNotification"), object: nil, userInfo: userInfo)
        }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        
        completionHandler([])
    }
    
    
    
    var notificationCategories: Set<UNNotificationCategory> {
        var options: UNNotificationActionOptions = [.authenticationRequired]
        let takeAction = UNNotificationAction(identifier: "takeDose", title: "Take Dose", options: options)
        
        options = []
        let snoozeAction = UNNotificationAction(identifier: "snoozeReminder", title: "Snooze", options: options)
        
        let doseCategory = UNNotificationCategory(identifier: "Dose Reminder",
                                                  actions: [takeAction, snoozeAction],
                                                  intentIdentifiers: [],
                                                  options: [])
        
        let doseCategoryAlt = UNNotificationCategory(identifier: "Dose Reminder - No Snooze",
                                                     actions: [takeAction],
                                                     intentIdentifiers: [],
                                                     options: [])
        
        options = [.authenticationRequired, .foreground]
        let refillAction = UNNotificationAction(identifier: "refillMed", title: "Refill Medicatin", options: options)
        let refillCategory = UNNotificationCategory(identifier: "Refill Reminder",
                                                    actions: [refillAction],
                                                    intentIdentifiers: [],
                                                    options: [])
        
        return [doseCategory, doseCategoryAlt, refillCategory]
    }
}

// MARK: - Application helper methods
extension AppDelegate {
    func setUserDefaults() {
        guard let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine") else {
            fatalError("No user defaults")
        }
        
        // Set first launch
        if defaults.value(forKey: "finishedFirstLaunch") == nil {
            defaults.set(false, forKey: "finishedFirstLaunch")
        }
        
        // Set sort order to "next dosage"
        if defaults.value(forKey: "sortOrder") == nil {
            defaults.set(SortOrder.nextDosage.rawValue, forKey: "sortOrder")
        }
        
        // Set snooze duration to 5 minutes
        if defaults.value(forKey: "snoozeLength") == nil {
            defaults.set(5, forKey: "snoozeLength")
        }
        
        // Set refill time to 3 days
        if defaults.value(forKey: "refillTime") == nil {
            defaults.set(3, forKey: "refillTime")
        }
        
        defaults.synchronize()
    }
}
