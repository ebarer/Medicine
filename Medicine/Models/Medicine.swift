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
    func calculateInterval(modDate: NSDate?) -> NSDate? {
        var returnDate: NSDate? = nil
        
        if let date = modDate {
            switch (intervalUnit) {
            case 0:
                let hr = Int(interval)
                let min = Int(60 * (interval % 1))
                
                returnDate = cal.dateByAddingUnit(NSCalendarUnit.Hour, value: hr, toDate: date, options: [])
                returnDate = cal.dateByAddingUnit(NSCalendarUnit.Minute, value: min, toDate: returnDate!, options: [])
            case 1:
                returnDate = cal.dateByAddingUnit(NSCalendarUnit.Day, value: Int(interval), toDate: date, options: [])
            case 2:
                returnDate = cal.dateByAddingUnit(NSCalendarUnit.WeekOfYear, value: Int(interval), toDate: date, options: [])
            default:
                returnDate = nil
            }
        }
        
        return returnDate
    }

    func takeNextDose(moc: NSManagedObjectContext) -> Bool {

        // Get time of next dose
        let currentDate = NSDate()
        var fireDate = calculateInterval(currentDate)

        // Ensure notification fire date is before final dosage time (if set)
        if let date = fireDate {
            if (timeEnd != 0.0) {
                let endTime = NSDate(timeInterval: timeEnd, sinceDate: cal.startOfDayForDate(currentDate))
                
                if (endTime.compare(date) == .OrderedAscending) {
                    fireDate = nil
                }
            }
        }
        
        // If no history, or no doses taken within previous 5 minutes
        let compareDate = cal.dateByAddingUnit(NSCalendarUnit.Minute, value: -5, toDate: currentDate, options: [])!
        if (lastDose == nil || lastDose!.date.compare(compareDate) == .OrderedAscending) {
            // Log current dosage as new history element
            let entity = NSEntityDescription.entityForName("History", inManagedObjectContext: moc)
            let newDose = History(entity: entity!, insertIntoManagedObjectContext: moc)
            newDose.medicine = self
            newDose.date = currentDate
            
            // Cancel previous notification
            cancelNotification()
            
            // Schedule new notification
            if let date = fireDate {
                scheduleNotification(date)
                return true
            }
        }
        
        // Otherwise do not reschedule next dose
        return false
    }
    
    func untakeLastDose(moc: NSManagedObjectContext) -> Bool {
        if let previous = lastDose {
            // Delete previous dose
            moc.deleteObject(previous)
        
            // Cancel previous notification
            cancelNotification()
        
            // Schedule new notification based on previous dose
            let fireDate = calculateInterval(lastDose?.date)
            if let date = fireDate {
                if date.compare(NSDate()) == .OrderedDescending {
                    scheduleNotification(date)
                }
                
                return true
            }
        }
        
        return false
    }
    
    
    // MARK: - Notification methods
    func setNotification() {
        if let date = nextDose {
            if date.compare(NSDate()) == .OrderedDescending {
                scheduleNotification(date)
            }
        }
    }
    
    func scheduleNotification(date: NSDate) {
        if let medName = name {
            let notification = UILocalNotification()
            
            notification.alertAction = "View Dose"
            notification.alertTitle = "Take \(medName)"
            notification.alertBody = String(format:"Time to take %g %@ of %@", dosageAmount, dosageType, medName)
            notification.soundName = UILocalNotificationDefaultSoundName
            notification.category = "Reminder"
            notification.userInfo = ["id": self.medicineID]
        
            notification.fireDate = date
        
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
        }
    }
    
    func snoozeNotification() {
        // Set snooze delay to 5 minutes
        let snoozeDelay = cal.dateByAddingUnit(NSCalendarUnit.Minute, value: 5, toDate: NSDate(), options: [])!
        
        // Cancel previous notification
        cancelNotification()
        
        // Schedule new notification
        scheduleNotification(snoozeDelay)
    }

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
    
    
    // MARK: - Member variables
    var type: Doses {
        get { return Doses(rawValue: self.dosageType)! }
        set { self.dosageType = newValue.rawValue }
    }
    
    var unit: Intervals {
        get { return Intervals(rawValue: self.intervalUnit)! }
        set { self.intervalUnit = newValue.rawValue }
    }
    
    
    // MARK: - Helper variables
    let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    
    var nextDose: NSDate? {
        return calculateInterval(lastDose?.date)
    }
    
    var lastDose: History?{
        if let lastHistory = history {
            if let object = lastHistory.firstObject {
                var dose = object as! History
                
                for next in lastHistory.array as! [History] {
                    if (dose.date.compare(next.date) == .OrderedAscending) {
                        dose = next
                    }
                }
                
                return dose;
            }
        }
        
        return nil
    }
    
    var isOverdue: Bool {
        if let date = nextDose {
            return (NSDate().compare(date) == .OrderedDescending)
        }
        
        return false
    }
}


// MARK: - Units Enum
enum Doses: Int16 {
    case None = -1
    case Pills = 0
    case Milligrams
    case Millilitres
    
    static var count: Int16 {
        return 3
    }
    
    func units(amount:Double?) -> String {
        switch self {
        case .Pills:
            if (amount != nil && amount == 1.0) {
                return "Pill"
            } else {
                return "Pills"
            }
        case .Milligrams: return "mg"
        case .Millilitres: return "mL"
        default: return ""
        }
    }
}


// MARK: - Frequencies Enum
enum Intervals: Int16, CustomStringConvertible {
    case None = 0
    case Hourly
    case Daily
    case Weekly
    
    static var count: Int16 {
        return 4
    }
    
    var description: String {
        switch self {
        case .None: return "None"
        case .Hourly: return "Hourly"
        case .Daily: return "Daily"
        case .Weekly: return "Weekly"
        }
    }
    
    var units: String {
        switch self {
        case .None: return "None"
        case .Hourly: return "Hour"
        case .Daily: return "Day"
        case .Weekly: return "Week"
        }
    }
    
    var unitsPlural: String {
        switch self {
        case .None: return "None"
        default: return units + "s"
        }
    }

}
