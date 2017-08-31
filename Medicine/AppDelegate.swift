//
//  AppDelegate.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-27.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData
import StoreKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let stack = CoreDataStack()!
    let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine")!
    var launchedShortcutItem: [AnyHashable: Any]?

    // MARK: - Application methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Handle views on startup
        if let tbc = self.window!.rootViewController as? UITabBarController {
            if let splitView = tbc.viewControllers?.filter({$0.isKind(of: UISplitViewController.self)}).first as? UISplitViewController {
                
                // Configure split view on startup
                splitView.delegate = self
                let detailNVC = splitView.viewControllers[1] as! UINavigationController
                detailNVC.topViewController?.navigationItem.leftBarButtonItem = splitView.displayModeButtonItem
                
                // Add IAP observer to MainVC
                let masterVC = splitView.viewControllers[0].childViewControllers[0] as! MainVC
                SKPaymentQueue.default().add(masterVC)
                NSLog("IAP transaction observer added")
            }
        }
        
        // Setup background fetch to reload reschedule notifications
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        // Register for notifications and actions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {(accepted, error) in
            if accepted {
                UNUserNotificationCenter.current().setNotificationCategories(self.notificationCategories)
                UNUserNotificationCenter.current().delegate = self
            } else {
                print("Notification access denied.")
            }
        }
        
        setUserDefaults()
        
        // Handle application shortcut
        if let _ = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            launchedShortcutItem = launchOptions
            return false
        }
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = Medicine.overdueCount()
        self.stack.save()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if let shortcutItem = launchedShortcutItem?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            _ = handleShortcut(shortcutItem)
        }
        
        launchedShortcutItem = nil
    }

    func applicationWillTerminate(_ application: UIApplication) {
        self.stack.save()
        
        // Remove IAP observers
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKind(of: UINavigationController.self)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKind(of: MainVC.self)}).first {
                SKPaymentQueue.default().remove(vc as! MainVC)
            }
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "rescheduleNotifications"), object: nil, userInfo: nil)
    }
    
    // MARK: - Background refresh
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "rescheduleNotifications"), object: nil, userInfo: nil)
        NSLog("Rescheduling notifications in the background")
        completionHandler(UIBackgroundFetchResult.newData)
        self.stack.save()
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
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        print("Received \"\(response.actionIdentifier)\" -> \(userInfo)")
        
        if response.actionIdentifier == "takeDose" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "takeDoseAction"), object: nil, userInfo: userInfo)
        }
        
        if response.actionIdentifier == "snoozeReminder" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "snoozeReminderAction"), object: nil, userInfo: userInfo)
        }
        
        if response.actionIdentifier == "refillMed" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refillAction"), object: nil, userInfo: userInfo)
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        let identifier = notification.request.identifier
        let userInfo = notification.request.content.userInfo
        let category = notification.request.content.categoryIdentifier

        print("\(identifier) (\(category)): \(userInfo)")
        NSLog("Local notification received: %@", userInfo)
        
        if category == "Dose Reminder" || category == "Dose Reminder - No Snooze" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "doseNotification"), object: nil, userInfo: userInfo)
        } else if category == "Refill Reminder" {
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
        
        // Set sort order to "next dosage"
        if defaults.value(forKey: "sortOrder") == nil {
            defaults.set(SortOrder.nextDosage.rawValue, forKey: "sortOrder")
        }
        
        // Set snooze duration to 5 minutes
        if (defaults.value(forKey: "snoozeLength") == nil) {
            defaults.set(5, forKey: "snoozeLength")
        }
        
        // Set refill time to 3 days
        if (defaults.value(forKey: "refillTime") == nil) {
            defaults.set(3, forKey: "refillTime")
        }
        
        defaults.synchronize()
    }
}

// MARK: - Application shortcut stack
extension AppDelegate {
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem))
    }

    func handleShortcut(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let action = shortcutItem.userInfo?["action"] else { return false }
        
        if let tbc = self.window!.rootViewController as? UITabBarController {
            if let splitView = tbc.viewControllers?.filter({$0.isKind(of: UISplitViewController.self)}).first as? UISplitViewController {
                let masterVC = splitView.viewControllers[0].childViewControllers[0] as! MainVC
                
                if masterVC.isViewLoaded {
                    masterVC.dismiss(animated: false, completion: nil)
                    
                    switch(String(describing: action)) {
                    case "addMedication":
                        masterVC.performSegue(withIdentifier: "addMedication", sender: self)
                    case "takeDose":
                        masterVC.performSegue(withIdentifier: "addDose", sender: self)
                    default: break
                    }
                    
                    launchedShortcutItem = nil
                    return true
                } else {
                    masterVC.launchedShortcutItem = self.launchedShortcutItem as [NSObject : AnyObject]?
                }
            }
        }
        
        return false
    }
}
