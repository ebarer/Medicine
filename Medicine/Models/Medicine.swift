//
//  Medicine.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-28.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class Medicine: NSManagedObject {

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.medicineID = NSUUID().UUIDString
    }
    
    
    // MARK: - Dose methods
    func nextDose() -> NSDate? {
        if let lastHistory = history {
            if let lastDose = lastHistory.lastObject {
                let dose = lastDose as! History
                return NSDate(timeInterval: dosageNext, sinceDate: dose.date)
            }
        }
        
        return nil
    }
    
    func takeNextDose(moc: NSManagedObjectContext) -> Bool {
        
        // Get time of next dose
        // ##TODO -- Switch to calendar mode for accuracy
        var multiplier:Float = 0;

        switch (frequencyInterval) {
        case 1:
            multiplier = 60;
        case 2:
            multiplier = 60 * 24;
        case 3:
            multiplier = 60 * 24 * 7;
        default:
            multiplier = 0;
        }
        
        dosageNext = NSTimeInterval(frequencyDuration * multiplier)
        let fireDate = nextDose()
        
        // Determine if time falls beyond final dosage time
        
        // Log current dosage as new history element
        let entity = NSEntityDescription.entityForName("History", inManagedObjectContext: moc)
        let newDose = History(entity: entity!, insertIntoManagedObjectContext: moc)
        newDose.date = NSDate()
        newDose.medicine = self
    
        // Cancel previous notification
        cancelNotification()
        
        // Schedule new notification
        if let date = fireDate {
            scheduleNotification(date)
            return true
        }
        
        return false
    }
    
    func untakeLastDose(moc: NSManagedObjectContext) -> Bool {
        return true
    }
    
    
    // MARK: - Reminder methods
    func setNotification() {
        if let date = nextDose() {
            scheduleNotification(date)
        }
    }
    
    func scheduleNotification(date: NSDate) {
        let notification = UILocalNotification()
        
        notification.alertAction = "View Dose"
        notification.alertTitle = "Take \(name)"
        notification.alertBody = String(format:"Time to take %g %@ of %@", dosageAmount, dosageType, name!)
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.category = "Reminder"
        notification.userInfo = ["id": self.medicineID]
        
        notification.fireDate = date
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    func snoozeNotification() {
        // Set snooze delay to 5 minutes
        let snoozeDelay = NSTimeInterval(10)
        
        // Cancel previous notification
        cancelNotification()
        
        // Schedule new notification
        scheduleNotification(NSDate(timeInterval: snoozeDelay, sinceDate: NSDate()))
    }
    
    // Cancel previous notification
    func cancelNotification() {
        let notifications = UIApplication.sharedApplication().scheduledLocalNotifications!
        for notification in notifications {
            if let id = notification.userInfo?["id"] as? String {
                if (id == self.medicineID) {
                    UIApplication.sharedApplication().cancelLocalNotification(notification)
                }
            }
        }
    }

}
