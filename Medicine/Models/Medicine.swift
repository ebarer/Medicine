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
    
    
    // MARK: - Class method
    class func getMedicine(arr meds: [Medicine], id: String) -> Medicine? {
        for med in meds {
            if med.medicineID == id {
                return med
            }
        }
        
        return nil
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
                    date = cal.dateBySettingHour(components.hour, minute: components.minute, second: 0, ofDate: date, options: [])!
                }
                
                returnDate = cal.dateByAddingUnit(NSCalendarUnit.Day, value: Int(interval), toDate: date, options: [])
            case .Weekly:
                returnDate = cal.dateByAddingUnit(NSCalendarUnit.WeekOfYear, value: Int(interval), toDate: date, options: [])
            }
        }
        
        return returnDate
    }

    func takeDose(moc: NSManagedObjectContext, date doseDate: NSDate) -> Bool {
        
        // If no history, or no doses taken within previous 5 minutes
        let compareDate = cal.dateByAddingUnit(NSCalendarUnit.Minute, value: -5, toDate: doseDate, options: [])!
        if (lastDose == nil || lastDose!.date.compare(compareDate) == .OrderedAscending) {
            addDose(moc, date: doseDate)
            
            return true
        }
        
        // Otherwise do not reschedule next dose
        return false
    }
    
    func addDose(moc: NSManagedObjectContext, date doseDate: NSDate) -> History {
        // Log current dosage as new history element
        let entity = NSEntityDescription.entityForName("History", inManagedObjectContext: moc)
        let newDose = History(entity: entity!, insertIntoManagedObjectContext: moc)
        newDose.medicine = self
        newDose.dosage = self.dosage
        newDose.dosageUnitInt = self.dosageUnitInt
        newDose.date = doseDate
        
        // Reschedule notification if newest addition
        if let date = calculateInterval(doseDate) {
            newDose.next = date
            
            if (date.compare(NSDate()) == .OrderedDescending) {
                // Cancel previous notification
                cancelNotification()
                
                // Schedule new notification
                scheduleNotification(date)
            }
        }
        
        return newDose
    }
    
    func untakeLastDose(moc: NSManagedObjectContext) -> Bool {
        if let previous = lastDose {
            // Delete previous dose
            moc.deleteObject(previous)
            
            // Commit changes
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.saveContext()
        
            // Cancel previous notification
            cancelNotification()
            
            // Reschedule notification based on previouse dose
            if let date = lastDose {
                if let next = date.next {
                    if next.compare(NSDate()) == .OrderedDescending {
                        scheduleNotification(next)
                    }
                }
            }
            
            return true
        }
        
        return false
    }
    
    func printNext() -> NSDate? {
        if let date = lastDose {
            return date.next
        } else if var alarm = intervalAlarm {
            // If interval alarm set and no previous doses taken
            if alarm.compare(NSDate()) == .OrderedAscending {
                alarm = calculateInterval(alarm)!
            }
            
            return alarm
        }
        
        return nil
    }
    
    func isOverdue() -> Bool {
        if let date = printNext() {
            return (NSDate().compare(date) == .OrderedDescending)
        }
        
        return false
    }
    
    
    // MARK: - Notification methods
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
    
    func scheduleNextNotification() {
        cancelNotification()
        
        if let date = nextDose {
            if date.compare(NSDate()) == .OrderedDescending {
                scheduleNotification(date)
            }
        } else if var alarm = intervalAlarm {
            // If interval alarm set and no previous doses taken
            if alarm.compare(NSDate()) == .OrderedAscending {
                alarm = calculateInterval(alarm)!
            }
            
            scheduleNotification(alarm)
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
    
    // Return next dose based on interval from most recent dose taken
    var nextDose: NSDate? {
        return calculateInterval(lastDose?.date)
    }
    
    // Return most recent dose taken
    var lastDose: History?{
        if let lastHistory = history {
            if let object = lastHistory.firstObject {
                var dose = object as! History
                
                for next in lastHistory.array as! [History] {
                    // Ignore if item is set to be deleted
                    if (!next.deleted && dose.date.compare(next.date) == .OrderedAscending) {
                        dose = next
                    }
                }
                
                return dose;
            }
        }
        
        return nil
    }

    private let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    
}

extension NSDate {

    // Determines if time is set to midnight
    func isMidnight() -> Bool {
        let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        let currentDate = NSDate()
        let components = cal.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: self)
        
        if let compare = cal.dateBySettingHour(components.hour, minute: components.minute, second: 0, ofDate: currentDate, options: []) {
            if (cal.isDate(compare, equalToDate: cal.startOfDayForDate(currentDate), toUnitGranularity: NSCalendarUnit.Minute)) {
                return true
            }
        }
        
        return false
    }
    
    func isDateInLastWeek() -> Bool {
        let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        let currentDate = NSDate()
        var val = false
        
        if self.compare(cal.dateByAddingUnit(NSCalendarUnit.WeekOfYear, value: -1, toDate: cal.startOfDayForDate(currentDate), options: [])!) == .OrderedDescending {
            if self.compare(currentDate) == .OrderedAscending {
                val = true
            }
        }
        
        return val
    }
    
    func isDateInWeek() -> Bool {
        let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        let currentDate = NSDate()
        var val = false
        
        if self.compare(cal.dateByAddingUnit(NSCalendarUnit.WeekOfYear, value: 1, toDate: cal.startOfDayForDate(currentDate), options: [])!) == .OrderedAscending {
            if self.compare(cal.dateByAddingUnit(NSCalendarUnit.Day, value: -1, toDate: cal.startOfDayForDate(currentDate), options: [])!) == .OrderedDescending {
                val = true
            }
        }

        return val
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
        return 2
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
        
        if (amount < 1 || amount >= 2) {
            string += "s"
        }
        
        return string
    }

}
