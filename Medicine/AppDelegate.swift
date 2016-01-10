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
        // Setup IAP observers and pass moc
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKindOfClass(UINavigationController)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKindOfClass(MainVC)}).first {
                SKPaymentQueue.defaultQueue().addTransactionObserver(vc as! MainVC)
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
            if notification.category == "Dose Reminder" {
                NSNotificationCenter.defaultCenter().postNotificationName("doseNotification", object: nil, userInfo: notification.userInfo)
                UIApplication.sharedApplication().cancelLocalNotification(notification)
            } else if notification.category == "Refill Reminder" {
                NSNotificationCenter.defaultCenter().postNotificationName("refillNotification", object: nil, userInfo: notification.userInfo)
                UIApplication.sharedApplication().cancelLocalNotification(notification)
            }
        }
        
        // Setup split view controller
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKindOfClass(UINavigationController)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKindOfClass(UISplitViewController)}).first {
                let svc = vc as! UISplitViewController
                svc.delegate = self
            }
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
        NSNotificationCenter.defaultCenter().postNotificationName("refreshMedication", object: nil, userInfo: nil)
        NSNotificationCenter.defaultCenter().postNotificationName("refreshDetails", object: nil, userInfo: nil)
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
        if topAsDetailController.med == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        
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
        
        if  UIDevice.currentDevice().identifierForVendor?.UUIDString == "104AFCAA-C1C8-4628-8B81-7ED680C8157B" ||
            UIDevice.currentDevice().identifierForVendor?.UUIDString == "3CF28B81-5657-465E-96B4-1E094CE335B3" ||
            UIDevice.currentDevice().identifierForVendor?.UUIDString == "A2AD279E-6719-4BAD-B5FA-250D90285D08" {
                defaults.setBool(true, forKey: "debug")      // Turn on debug mode for approved devices
        } else {
            defaults.setBool(false, forKey: "debug")         // Disable debug
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
        
        let refillAction = UIMutableUserNotificationAction()
        refillAction.identifier = "refillMed"
        refillAction.title = "Refill Medication"
        refillAction.activationMode = UIUserNotificationActivationMode.Foreground
        refillAction.destructive = false
        refillAction.authenticationRequired = true
        
        let refillCategory = UIMutableUserNotificationCategory()
        refillCategory.identifier = "Refill Reminder"
        refillCategory.setActions([refillAction], forContext: UIUserNotificationActionContext.Default)
        
        let categories = NSSet(array: [doseCategory, refillCategory])
        return UIUserNotificationSettings(forTypes: notificationType, categories: categories as? Set<UIUserNotificationCategory>)
    }
    
    
    // MARK: - Background refresh
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        NSNotificationCenter.defaultCenter().postNotificationName("rescheduleNotifications", object: nil, userInfo: ["activator":"background"])
        completionHandler(UIBackgroundFetchResult.NewData)
    }
    
    
    // MARK: - Application shortcut stack
    
    var launchedShortcutItem: [NSObject: AnyObject]?
    
    @available(iOS 9.0, *)
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem))
    }
    
    @available(iOS 9.0, *)
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
        if let info = notification.userInfo {
            NSLog("Local notification received: %@", info)
        } else {
            NSLog("Local notification received (no info): %@", notification)
        }
        
        if notification.category == "Dose Reminder" {
            NSNotificationCenter.defaultCenter().postNotificationName("doseNotification", object: nil, userInfo: notification.userInfo)
            UIApplication.sharedApplication().cancelLocalNotification(notification)
        } else if notification.category == "Refill Reminder" {
            NSNotificationCenter.defaultCenter().postNotificationName("refillNotification", object: nil, userInfo: notification.userInfo)
            UIApplication.sharedApplication().cancelLocalNotification(notification)
        }
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
    

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.ebarer.Medicine" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Medicine", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        let options = [NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true]
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                // abort()
            }
        }
    }

}

