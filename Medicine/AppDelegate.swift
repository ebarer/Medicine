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
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var launchedShortcutItem: [NSObject: AnyObject]?
    let defaults = NSUserDefaults(suiteName: "group.com.ebarer.Medicine")!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Get view controllers and setup IAP observers
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKindOfClass(UINavigationController)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKindOfClass(MainTVC)}).first {
                SKPaymentQueue.defaultQueue().addTransactionObserver(vc as! MainTVC)
                (vc as! MainTVC).moc = self.managedObjectContext
            }
        }
        
        
        // Register for notifications and actions
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
        
        let category = UIMutableUserNotificationCategory()
            category.identifier = "Reminder"
            category.setActions([takeAction, snoozeAction], forContext: UIUserNotificationActionContext.Default)
        
        let categories = NSSet(array: [category])
        let settings = UIUserNotificationSettings(forTypes: notificationType, categories: categories as? Set<UIUserNotificationCategory>)

        application.registerUserNotificationSettings(settings)
        
        
        // Set user preferences
        guard let defaults = NSUserDefaults(suiteName: "group.com.ebarer.Medicine") else { fatalError("No user defaults") }
        
        if !defaults.boolForKey("firstLaunch") {
            defaults.setInteger(1, forKey: "sortOrder")         // Set sort order to "next dosage"
            defaults.setInteger(5, forKey: "snoozeLength")      // Set snooze duration to 5 minutes
            defaults.setBool(false, forKey: "debug")            // Disable debug
            defaults.synchronize()
        }
        
        if UIDevice.currentDevice().identifierForVendor?.UUIDString == "1236238D-3703-4DEA-93A7-B521FE341AF5" ||
           UIDevice.currentDevice().identifierForVendor?.UUIDString == "89AED7B3-EAAB-4E5C-8CBE-CE5A48B311EE" {
            defaults.setBool(true, forKey: "debug")      // Set snooze duration to 5 minutes
        }
        
        
        // Handle application shortcut
        if #available(iOS 9.0, *) {
            if let _ = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
                launchedShortcutItem = launchOptions
                return false
            }
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Remove IAP observers
        if let viewControllers = self.window?.rootViewController?.childViewControllers {
            for viewController in viewControllers {
                if viewController.isKindOfClass(MainTVC) {
                    let vc = viewController as! MainTVC
                    SKPaymentQueue.defaultQueue().removeTransactionObserver(vc)
                }
            }
        }
    }
    
    func applicationDidEnterBackground(application: UIApplication) {}
    
    func applicationWillEnterForeground(application: UIApplication) {}
    
    func applicationDidBecomeActive(application: UIApplication) {
        if #available(iOS 9.0, *) {
            if let shortcutItem = launchedShortcutItem?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
                handleShortcut(shortcutItem)
            }
            
            launchedShortcutItem = nil
            return
        }
        
        return
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
        
        // Remove IAP observers
        if let viewControllers = self.window?.rootViewController?.childViewControllers {
            for viewController in viewControllers {
                if viewController.isKindOfClass(MainTVC) {
                    let vc = viewController as! MainTVC
                    SKPaymentQueue.defaultQueue().removeTransactionObserver(vc)
                }
            }
        }
    }
    
    
    // MARK: - Application shortcut stack
    
    @available(iOS 9.0, *)
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem))
    }
    
    @available(iOS 9.0, *)
    func handleShortcut(shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let action = shortcutItem.userInfo?["action"] else { return false }
        
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKindOfClass(UINavigationController)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKindOfClass(MainTVC)}).first {
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
                    (vc as! MainTVC).launchedShortcutItem = self.launchedShortcutItem
                }
            }
        }
        
        return false
    }
    
    
    // MARK: - Push Notifications stack
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        application.registerUserNotificationSettings(notificationSettings)
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        NSNotificationCenter.defaultCenter().postNotificationName("medNotification", object: nil, userInfo: notification.userInfo)
        
        if let vcs = window!.rootViewController?.childViewControllers.filter({$0.isKindOfClass(UINavigationController)}).first {
            if let vc = vcs.childViewControllers.filter({$0.isKindOfClass(MainTVC)}).first {
                SKPaymentQueue.defaultQueue().addTransactionObserver(vc as! MainTVC)
                (vc as! MainTVC).updateHeader()
            }
        }
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        if identifier == "takeDose" {
            NSNotificationCenter.defaultCenter().postNotificationName("takeDoseNotification", object: nil, userInfo: notification.userInfo)
        } else if identifier == "snoozeReminder" {
            NSNotificationCenter.defaultCenter().postNotificationName("snoozeReminderNotification", object: nil, userInfo: notification.userInfo)
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

