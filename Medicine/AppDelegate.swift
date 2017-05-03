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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine")!

    
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
        application.registerUserNotificationSettings(notificationSettings())

        setUserDefaults()
        
        // Handle application shortcut
        if let _ = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            launchedShortcutItem = launchOptions
            return false
        }
        
        // Handle local notification
        if let notification = launchOptions?[UIApplicationLaunchOptionsKey.localNotification] as? UILocalNotification {
            // self.application(application, didReceiveLocalNotification: notification)
            self.perform(#selector(postNotification(_:)), with: notification, afterDelay: 1.0)
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Remove IAP observers
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKind(of: UINavigationController.self)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKind(of: MainVC.self)}).first {
                SKPaymentQueue.default().remove(vc as! MainVC)
            }
        }
        
        UIApplication.shared.cancelAllLocalNotifications()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "rescheduleNotifications"), object: nil, userInfo: nil)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Remove IAP observers
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKind(of: UINavigationController.self)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKind(of: MainVC.self)}).first {
                SKPaymentQueue.default().remove(vc as! MainVC)
            }
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Setup IAP observers and pass moc
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKind(of: UINavigationController.self)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKind(of: MainVC.self)}).first {
                SKPaymentQueue.default().add(vc as! MainVC)
            }
        }
        
        UIApplication.shared.cancelAllLocalNotifications()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "rescheduleNotifications"), object: nil, userInfo: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Setup IAP observers and pass moc
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKind(of: UINavigationController.self)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKind(of: MainVC.self)}).first {
                SKPaymentQueue.default().add(vc as! MainVC)
            }
        }
        
        if let shortcutItem = launchedShortcutItem?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            _ = handleShortcut(shortcutItem)
        }
        
        launchedShortcutItem = nil
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
        
        // Remove IAP observers
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKind(of: UINavigationController.self)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKind(of: MainVC.self)}).first {
                SKPaymentQueue.default().remove(vc as! MainVC)
            }
        }
        
        UIApplication.shared.cancelAllLocalNotifications()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "rescheduleNotifications"), object: nil, userInfo: nil)
    }
    
    
    // MARK: - Split view
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
    
    
    // MARK: - Application helper methods
    func setUserDefaults() {
        guard let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine") else { fatalError("No user defaults") }
        
        if defaults.value(forKey: "sortOrder") == nil {
            // Set sort order to "next dosage"
            defaults.set(SortOrder.nextDosage.rawValue, forKey: "sortOrder")
        }
        
        if (defaults.value(forKey: "snoozeLength") == nil) {
            // Set snooze duration to 5 minutes
            defaults.set(5, forKey: "snoozeLength")
        }
        
        if (defaults.value(forKey: "refillTime") == nil) {
            // Set refill time to 3 days
            defaults.set(3, forKey: "refillTime")
        }
        
        defaults.synchronize()
    }
    
    func notificationSettings() -> UIUserNotificationSettings {
        let notificationType: UIUserNotificationType = [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound]
        
        let takeAction = UIMutableUserNotificationAction()
        takeAction.identifier = "takeDose"
        takeAction.title = "Take Dose"
        takeAction.activationMode = UIUserNotificationActivationMode.background
        takeAction.isDestructive = false
        takeAction.isAuthenticationRequired = true
        
        let snoozeAction = UIMutableUserNotificationAction()
        snoozeAction.identifier = "snoozeReminder"
        snoozeAction.title = "Snooze"
        snoozeAction.activationMode = UIUserNotificationActivationMode.background
        snoozeAction.isDestructive = false
        snoozeAction.isAuthenticationRequired = false
        
        let doseCategory = UIMutableUserNotificationCategory()
        doseCategory.identifier = "Dose Reminder"
        doseCategory.setActions([takeAction, snoozeAction], for: UIUserNotificationActionContext.default)
        
        let altDoseCategory = UIMutableUserNotificationCategory()
        altDoseCategory.identifier = "Dose Reminder - No Snooze"
        altDoseCategory.setActions([takeAction], for: UIUserNotificationActionContext.default)
        
        let refillAction = UIMutableUserNotificationAction()
        refillAction.identifier = "refillMed"
        refillAction.title = "Refill Medication"
        refillAction.activationMode = UIUserNotificationActivationMode.foreground
        refillAction.isDestructive = false
        refillAction.isAuthenticationRequired = true
        
        let refillCategory = UIMutableUserNotificationCategory()
        refillCategory.identifier = "Refill Reminder"
        refillCategory.setActions([refillAction], for: UIUserNotificationActionContext.default)
        
        let categories = NSSet(array: [doseCategory, altDoseCategory, refillCategory])
        return UIUserNotificationSettings(types: notificationType, categories: categories as? Set<UIUserNotificationCategory>)
    }
    
    
    // MARK: - Background refresh
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "rescheduleNotifications"), object: nil, userInfo: nil)
        NSLog("Rescheduling notifications in the background")
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    
    // MARK: - Application shortcut stack
    var launchedShortcutItem: [AnyHashable: Any]?

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
    
    
    // MARK: - Push Notifications stack
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        self.perform(#selector(postNotification(_:)), with: notification)
    }
    
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
        guard let action = identifier else {
            NSLog("Local action received: no identifier")
            completionHandler()
            return
        }
        
        guard let info = notification.userInfo else {
            NSLog("Local action (%@) received: no info", action)
            completionHandler()
            return
        }
        
        NSLog("Local action (%@) received: %@", action, info)
        
        if identifier == "takeDose" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "takeDoseAction"), object: nil, userInfo: notification.userInfo)
            UIApplication.shared.cancelLocalNotification(notification)
        }
        
        if identifier == "snoozeReminder" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "snoozeReminderAction"), object: nil, userInfo: notification.userInfo)
            UIApplication.shared.cancelLocalNotification(notification)
        }
        
        if identifier == "refillMed" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refillAction"), object: nil, userInfo: notification.userInfo)
            UIApplication.shared.cancelLocalNotification(notification)
        }
        
        completionHandler()
    }
    
    func postNotification(_ notification: UILocalNotification) {
        if let info = notification.userInfo {
            NSLog("Local notification received: %@", info)
        } else {
            NSLog("Local notification received (no info): %@", notification)
        }
        
        if notification.category == "Dose Reminder" || notification.category == "Dose Reminder - No Snooze" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "doseNotification"), object: nil, userInfo: notification.userInfo)
            UIApplication.shared.cancelLocalNotification(notification)
        } else if notification.category == "Refill Reminder" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refillNotification"), object: nil, userInfo: notification.userInfo)
            UIApplication.shared.cancelLocalNotification(notification)
        }
    }
    

    // MARK: - Core Data stack
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.ebarer.Medicine" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var applicationGroupDirectory: URL = {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.ebarer.Medicine")!
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Medicine", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
        // This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let oldURL = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        let url = self.applicationGroupDirectory.appendingPathComponent("Medicine.sqlite")
        
        let options = [NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true]
        var failureReason = "There was an error creating or loading the application's saved data."
        
        do {
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw CoreDataError.invalidPersistentStore
            }
            
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
            NSLog("Loaded persistent store correctly")
        } catch {
            NSLog("Failed to load persistent store coordinator from group, will attempt to migrate old store")

            do {
                let oldStore = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: oldURL, options: options)
                NSLog("Old store \(oldStore)")
                let migratedStore = try coordinator.migratePersistentStore(oldStore, to: url, options: nil, withType: NSSQLiteStoreType)
                NSLog("Migrated store \(migratedStore)")
            } catch {
                NSLog("Failed to load persistent store after migration attempt")
                abort()
            }
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
        // This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let error = error as NSError
                NSLog("Unable to save context: \(error), \(error.userInfo)")
                abort()
            }
        }
    }

}


// MARK: - Errors Enum
enum CoreDataError: Error {
    case invalidPersistentStore
}
