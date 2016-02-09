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
    let defaults = NSUserDefaults(suiteName: "group.com.ebarer.Medicine")!

    
    // MARK: - Application methods
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Handle views on startup
        if let tbc = self.window!.rootViewController as? UITabBarController {
            if let splitView = tbc.viewControllers?.filter({$0.isKindOfClass(UISplitViewController)}).first as? UISplitViewController {
                
                // Configure split view on startup
                splitView.delegate = self
                let detailNVC = splitView.viewControllers[1] as! UINavigationController
                detailNVC.topViewController?.navigationItem.leftBarButtonItem = splitView.displayModeButtonItem()
                
                // Add IAP observer to MainVC
                let masterVC = splitView.viewControllers[0].childViewControllers[0] as! MainVC
                SKPaymentQueue.defaultQueue().addTransactionObserver(masterVC)
                NSLog("IAP transaction observer added")
            }
            
            if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKindOfClass(UINavigationController)}).first {
                if let vc = vcs.childViewControllers.filter({$0.isKindOfClass(MainVC)}).first {
                    SKPaymentQueue.defaultQueue().addTransactionObserver(vc as! MainVC)
                }
            }
        }
        
        // Setup background fetch to reload reschedule notifications
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        // Register for notifications and actions
        application.registerUserNotificationSettings(notificationSettings())

        setUserDefaults()
        
        // Handle application shortcut
        if let _ = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
            launchedShortcutItem = launchOptions
            return false
        }
        
        // Handle local notification
        if let notification = launchOptions?[UIApplicationLaunchOptionsLocalNotificationKey] as? UILocalNotification {
            // self.application(application, didReceiveLocalNotification: notification)
            self.performSelector("postNotification:", withObject: notification, afterDelay: 1.0)
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Remove IAP observers
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKindOfClass(UINavigationController)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKindOfClass(MainVC)}).first {
                SKPaymentQueue.defaultQueue().removeTransactionObserver(vc as! MainVC)
            }
        }
        
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        NSNotificationCenter.defaultCenter().postNotificationName("rescheduleNotifications", object: nil, userInfo: nil)
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Remove IAP observers
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKindOfClass(UINavigationController)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKindOfClass(MainVC)}).first {
                SKPaymentQueue.defaultQueue().removeTransactionObserver(vc as! MainVC)
            }
        }
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Setup IAP observers and pass moc
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKindOfClass(UINavigationController)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKindOfClass(MainVC)}).first {
                SKPaymentQueue.defaultQueue().addTransactionObserver(vc as! MainVC)
            }
        }
        
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        NSNotificationCenter.defaultCenter().postNotificationName("rescheduleNotifications", object: nil, userInfo: nil)
        NSNotificationCenter.defaultCenter().postNotificationName("refreshView", object: nil)
        NSNotificationCenter.defaultCenter().postNotificationName("refreshMain", object: nil)
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Setup IAP observers and pass moc
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKindOfClass(UINavigationController)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKindOfClass(MainVC)}).first {
                SKPaymentQueue.defaultQueue().addTransactionObserver(vc as! MainVC)
            }
        }
        
        if let shortcutItem = launchedShortcutItem?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
            handleShortcut(shortcutItem)
        }
        
        launchedShortcutItem = nil
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
        
        // Remove IAP observers
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKindOfClass(UINavigationController)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKindOfClass(MainVC)}).first {
                SKPaymentQueue.defaultQueue().removeTransactionObserver(vc as! MainVC)
            }
        }
        
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        NSNotificationCenter.defaultCenter().postNotificationName("rescheduleNotifications", object: nil, userInfo: nil)
    }
    
    
    // MARK: - Split view
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? MedicineDetailsTVC else { return false }
        
        // If detail view is empty, return true to dismiss on launch
        if topAsDetailController.med == nil {
            return true
        }
        
        return false
    }
    
    func splitViewController(svc: UISplitViewController, shouldHideViewController vc: UIViewController, inOrientation orientation: UIInterfaceOrientation) -> Bool {
        return false
    }
    
    
    // MARK: - Application helper methods
    func setUserDefaults() {
        guard let defaults = NSUserDefaults(suiteName: "group.com.ebarer.Medicine") else { fatalError("No user defaults") }
        
        if defaults.valueForKey("sortOrder") == nil {
            // Set sort order to "next dosage"
            defaults.setInteger(SortOrder.NextDosage.rawValue, forKey: "sortOrder")
        }
        
        if (defaults.valueForKey("snoozeLength") == nil) {
            // Set snooze duration to 5 minutes
            defaults.setInteger(5, forKey: "snoozeLength")
        }
        
        if (defaults.valueForKey("refillTime") == nil) {
            // Set refill time to 3 days
            defaults.setInteger(3, forKey: "refillTime")
        }
        
        defaults.synchronize()
    }
    
    func notificationSettings() -> UIUserNotificationSettings {
        let notificationType: UIUserNotificationType = [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound]
        
        let takeAction = UIMutableUserNotificationAction()
        takeAction.identifier = "takeDose"
        takeAction.title = "Take Dose"
        takeAction.activationMode = UIUserNotificationActivationMode.Background
        takeAction.destructive = false
        takeAction.authenticationRequired = true
        
        let snoozeAction = UIMutableUserNotificationAction()
        snoozeAction.identifier = "snoozeReminder"
        snoozeAction.title = "Snooze"
        snoozeAction.activationMode = UIUserNotificationActivationMode.Background
        snoozeAction.destructive = false
        snoozeAction.authenticationRequired = false
        
        let doseCategory = UIMutableUserNotificationCategory()
        doseCategory.identifier = "Dose Reminder"
        doseCategory.setActions([takeAction, snoozeAction], forContext: UIUserNotificationActionContext.Default)
        
        let altDoseCategory = UIMutableUserNotificationCategory()
        altDoseCategory.identifier = "Dose Reminder - No Snooze"
        altDoseCategory.setActions([takeAction], forContext: UIUserNotificationActionContext.Default)
        
        let refillAction = UIMutableUserNotificationAction()
        refillAction.identifier = "refillMed"
        refillAction.title = "Refill Medication"
        refillAction.activationMode = UIUserNotificationActivationMode.Foreground
        refillAction.destructive = false
        refillAction.authenticationRequired = true
        
        let refillCategory = UIMutableUserNotificationCategory()
        refillCategory.identifier = "Refill Reminder"
        refillCategory.setActions([refillAction], forContext: UIUserNotificationActionContext.Default)
        
        let categories = NSSet(array: [doseCategory, altDoseCategory, refillCategory])
        return UIUserNotificationSettings(forTypes: notificationType, categories: categories as? Set<UIUserNotificationCategory>)
    }
    
    
    // MARK: - Background refresh
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        NSNotificationCenter.defaultCenter().postNotificationName("rescheduleNotifications", object: nil, userInfo: nil)
        NSLog("Rescheduling notifications in the background")
        completionHandler(UIBackgroundFetchResult.NewData)
    }
    
    
    // MARK: - Application shortcut stack
    var launchedShortcutItem: [NSObject: AnyObject]?

    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem))
    }

    func handleShortcut(shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let action = shortcutItem.userInfo?["action"] else { return false }
        
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKindOfClass(UINavigationController)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKindOfClass(MainVC)}).first {
                if vc.isViewLoaded() {
                    
                    vc.dismissViewControllerAnimated(false, completion: nil)
                    
                    switch(String(action)) {
                    case "addMedication":
                        vc.performSegueWithIdentifier("addMedication", sender: self)
                    case "takeDose":
                        vc.performSegueWithIdentifier("addDose", sender: self)
                    default: break
                    }

                    launchedShortcutItem = nil
                    return true
                } else {
                    (vc as! MainVC).launchedShortcutItem = self.launchedShortcutItem
                }
            }
        }
        
        return false
    }
    
    
    // MARK: - Push Notifications stack
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        self.performSelector("postNotification:", withObject: notification)
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
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
            NSNotificationCenter.defaultCenter().postNotificationName("takeDoseAction", object: nil, userInfo: notification.userInfo)
            UIApplication.sharedApplication().cancelLocalNotification(notification)
        }
        
        if identifier == "snoozeReminder" {
            NSNotificationCenter.defaultCenter().postNotificationName("snoozeReminderAction", object: nil, userInfo: notification.userInfo)
            UIApplication.sharedApplication().cancelLocalNotification(notification)
        }
        
        if identifier == "refillMed" {
            NSNotificationCenter.defaultCenter().postNotificationName("refillAction", object: nil, userInfo: notification.userInfo)
            UIApplication.sharedApplication().cancelLocalNotification(notification)
        }
        
        completionHandler()
    }
    
    func postNotification(notification: UILocalNotification) {
        if let info = notification.userInfo {
            NSLog("Local notification received: %@", info)
        } else {
            NSLog("Local notification received (no info): %@", notification)
        }
        
        if notification.category == "Dose Reminder" || notification.category == "Dose Reminder - No Snooze" {
            NSNotificationCenter.defaultCenter().postNotificationName("doseNotification", object: nil, userInfo: notification.userInfo)
            UIApplication.sharedApplication().cancelLocalNotification(notification)
        } else if notification.category == "Refill Reminder" {
            NSNotificationCenter.defaultCenter().postNotificationName("refillNotification", object: nil, userInfo: notification.userInfo)
            UIApplication.sharedApplication().cancelLocalNotification(notification)
        }
    }
    

    // MARK: - Core Data stack
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.ebarer.Medicine" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var applicationGroupDirectory: NSURL = {
        return NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.com.ebarer.Medicine")!
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Medicine", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
        // This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let oldURL = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        let url = self.applicationGroupDirectory.URLByAppendingPathComponent("Medicine.sqlite")
        let options = [NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true]
        var failureReason = "There was an error creating or loading the application's saved data."
        
        do {
            guard NSFileManager.defaultManager().fileExistsAtPath(url.path!) else {
                throw CoreDataError.InvalidPersistentStore
            }
            
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options)
            NSLog("Loaded persistent store correctly")
        } catch {
            NSLog("Failed to load persistent store coordinator from group, will attempt to migrate old store")

            do {
                let oldStore = try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: oldURL, options: options)
                NSLog("Old store \(oldStore)")
                let migratedStore = try coordinator.migratePersistentStore(oldStore, toURL: url, options: nil, withType: NSSQLiteStoreType)
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
        var managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        print(managedObjectContext)
        return managedObjectContext
    }()

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let error = error as! NSError
                NSLog("Unable to save context: \(error), \(error.userInfo)")
                abort()
            }
        }
    }

}


// MARK: - Errors Enum
enum CoreDataError: ErrorType {
    case InvalidPersistentStore
}