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
        
        if var date = modDate {
            switch (intervalUnit) {
            case .Hourly:
                let hr = Int(interval)
                let min = Int(60 * (interval % 1))
                
                returnDate = cal.dateByAddingUnit(NSCalendarUnit.Hour, value: hr, toDate: date, options: [])
                returnDate = cal.dateByAddingUnit(NSCalendarUnit.Minute, value: min, toDate: returnDate!, options: [])
            case .Daily:
                // Get alarm hour and minute components if set
                if let alarm = intervalAlarm {
                    let components = cal.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: alarm)
                    date = cal.dateBySettingHour(components.hour, minute: components.minute, second: 0, ofDate: NSDate(), options: [])!
                }
                
                returnDate = cal.dateByAddingUnit(NSCalendarUnit.Day, value: Int(interval), toDate: date, options: [])
            case .Weekly:
                returnDate = cal.dateByAddingUnit(NSCalendarUnit.WeekOfYear, value: Int(interval), toDate: date, options: [])
            }
        }
        
        return returnDate
    }

    func takeNextDose(moc: NSManagedObjectContext) -> Bool {

        // Get time of next dose
        let currentDate = NSDate()
        
        // If no history, or no doses taken within previous 5 minutes
        let compareDate = cal.dateByAddingUnit(NSCalendarUnit.Minute, value: -5, toDate: currentDate, options: [])!
        if (lastDose == nil || lastDose!.date.compare(compareDate) == .OrderedAscending) {
            // Log current dosage as new history element
            let entity = NSEntityDescription.entityForName("History", inManagedObjectContext: moc)
            let newDose = History(entity: entity!, insertIntoManagedObjectContext: moc)
            newDose.medicine = self
            newDose.date = currentDate
            newDose.next = calculateInterval(currentDate)
            
            // Cancel previous notification
            cancelNotification()
            
            // Schedule new notification
            if let date = newDose.next {
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
            notification.alertBody = String(format:"Time to take %g %@ of %@", dosage, dosageUnit.units(dosage), medName)
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
    var dosageUnit: Doses {
        get { return Doses(rawValue: self.dosageUnitInt)! }
        set { self.dosageUnitInt = newValue.rawValue }
    }
    
    var intervalUnit: Intervals {
        get { return Intervals(rawValue: self.intervalUnitInt)! }
        set { self.intervalUnitInt = newValue.rawValue }
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
    
    func printNext() -> NSDate? {
        return lastDose?.next
    }
    
    func isOverdue() -> Bool {
        if let date = printNext() {
            return (NSDate().compare(date) == .OrderedDescending)
        }
        
        return false
    }
    
    func isMidnight() -> Bool {
        if let alarm = intervalAlarm {
            let currentDate = NSDate()
            let components = cal.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: alarm)
            if let compare = cal.dateBySettingHour(components.hour, minute: components.minute, second: 0, ofDate: currentDate, options: []) {
                if (cal.isDate(compare, equalToDate: cal.startOfDayForDate(currentDate), toUnitGranularity: NSCalendarUnit.Minute)) {
                    return true
                }
            }
        }
        
        return false
    }
}


// MARK: - Units Enum
enum Doses: Int16, CustomStringConvertible {
    case Pills
    case Milligrams
    case Millilitres
    
    static var count: Int {
        return 3
    }
    
    var description: String {
        switch self {
        case .Pills: return "Pills"
        case .Milligrams: return "Milligrams"
        case .Millilitres: return "Millilitres"
        }
    }
    
    func units(amount: Float?) -> String {
        switch self {
        case .Pills:
            if (amount != nil && amount == 1.0) {
                return "pill"
            } else {
                return "pills"
            }
        case .Milligrams: return "mg"
        case .Millilitres: return "ml"
        }
    }
}


// MARK: - Frequencies Enum
enum Intervals: Int16, CustomStringConvertible {
    case Hourly
    case Daily
    case Weekly
    
    static var count: Int {
        return 3
    }
    
    var description: String {
        switch self {
        case .Hourly: return "Hourly"
        case .Daily: return "Daily"
        case .Weekly: return "Weekly"
        }
    }
    
    func units(amount: Float?) -> String {
        var string = ""
        
        switch self {
        case .Hourly: string = "hour"
        case .Daily: string = "day"
        case .Weekly: string = "week"
        }
        
        if (amount != 1) {
            string += "s"
        }
        
        return string
    }

}
