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
    
    
    // MARK: - Enum variables
    private let cal = NSCalendar.currentCalendar()
    
    var dosageUnit: Doses {
        get { return Doses(rawValue: self.dosageUnitInt)! }
        set { self.dosageUnitInt = newValue.rawValue }
    }
    
    var intervalUnit: Intervals {
        get { return Intervals(rawValue: self.intervalUnitInt)! }
        set { self.intervalUnitInt = newValue.rawValue }
    }
    

    // MARK: - Member variables
    var nextDose: NSDate? {
        do {
            return try calculateNextDose()
        } catch {
            return nil
        }
    }

    var lastDose: History? {
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
    
    var scheduledNotification: UILocalNotification? {
        let notifications = UIApplication.sharedApplication().scheduledLocalNotifications!
        for notification in notifications {
            if let id = notification.userInfo?["id"] as? String {
                if (id == self.medicineID) {
                    return notification
                }
            }
        }
        
        return nil
    }
    
    func isOverdue() -> (flag: Bool, lastDose: NSDate?) {
        // Medicine can't be overdue if reminders are disabled
        if let date = lastDose?.next where reminderEnabled == true {
            if date.compare(NSDate()) == .OrderedAscending {
                return (true, date)
            }
        }

        return (false, nil)
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
    
    
    // MARK: - Initialization method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.medicineID = NSUUID().UUIDString
    }
    
    
    // MARK: - Action (dose) methods
    func takeDose(moc: NSManagedObjectContext, date doseDate: NSDate) throws -> Bool {
        // Throw error if another dose has been taken within the previous 5 minutes
        let compareDate = cal.dateByAddingUnit(NSCalendarUnit.Minute, value: -5, toDate: doseDate, options: [])!
        
        if lastDose != nil {
            guard lastDose?.date.compare(compareDate) == .OrderedAscending else {
                throw MedicineError.TooSoon
            }
        }
        
        addDose(moc, date: doseDate)
        return true
    }
    
    func addDose(moc: NSManagedObjectContext, date doseDate: NSDate) -> History {
        // Log current dosage as new history element
        let entity = NSEntityDescription.entityForName("History", inManagedObjectContext: moc)
        
        let newDose = History(entity: entity!, insertIntoManagedObjectContext: moc)
        newDose.medicine = self
        newDose.dosage = self.dosage
        newDose.dosageUnitInt = self.dosageUnitInt
        newDose.date = doseDate
        
        do {
            newDose.next = try calculateNextDose(doseDate)
        } catch {
            newDose.next = nil
        }
        
        print(newDose)
        
        // Only reschedule notification if dose is medications latest dose
        if let lastDose = self.lastDose {
            if doseDate.compare(lastDose.date) == .OrderedAscending {
                return newDose
            }
        }
        
        scheduleNextNotification()
        return newDose
    }
    
    func untakeLastDose(moc: NSManagedObjectContext) -> Bool {
        if let lastDose = lastDose {
            moc.deleteObject(lastDose)
            scheduleNextNotification()
            return true
        }
        
        return false
    }
    
    
    // MARK: - Notification methods
    func scheduleNotification(date: NSDate) throws {
        // Schedule if the user wants a reminder and the reminder date is in the future
        guard date.compare(NSDate()) == .OrderedDescending else {
            throw MedicineError.DatePassed
        }
        
        guard reminderEnabled == true else {
            throw MedicineError.ReminderDisabled
        }
        
        guard let name = name else {
            throw MedicineError.InvalidName
        }

        let notification = UILocalNotification()
        notification.alertAction = "View Dose"
        notification.alertTitle = "Take \(name)"
        notification.alertBody = String(format:"Time to take %g %@ of %@", dosage, dosageUnit.units(dosage), name)
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.category = "Reminder"
        notification.userInfo = ["id": self.medicineID]
        notification.fireDate = date
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    func scheduleNextNotification() -> Bool {
        guard let date = nextDose else {
            return false
        }
        
        cancelNotification()
        
        do {
            try scheduleNotification(date)
            return true
        } catch {
            return false
        }
    }
    
    func snoozeNotification() -> Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
        var snoozeDate = NSDate()
        
        // Set snooze delay to user selection or 5 minutes
        if defaults.valueForKey("snoozeLength") != nil {
            let val = defaults.valueForKey("snoozeLength") as! Int
            snoozeDate = cal.dateByAddingUnit(NSCalendarUnit.Minute, value: val, toDate: NSDate(), options: [])!
        } else {
            snoozeDate = cal.dateByAddingUnit(NSCalendarUnit.Minute, value: 5, toDate: NSDate(), options: [])!
        }
        
        // Schedule new notification
        do {
            try scheduleNotification(snoozeDate)
            return true
        } catch {
            return false
        }
    }
    
    func cancelNotification() {
        if let notification = scheduledNotification {
            UIApplication.sharedApplication().cancelLocalNotification(notification)
        }
    }
    
    
    // MARK: - Helper method
    
    func calculateNextDose(date: NSDate? = nil) throws -> NSDate? {
        switch(intervalUnit) {
        case .Hourly:
            let hr = Int(interval)
            let min = Int(60 * (interval % 1))
            
            // Calculate interval from date provided
            if let date = date {
                var next = cal.dateByAddingUnit(NSCalendarUnit.Hour, value: hr, toDate: date, options: [])!
                next = cal.dateByAddingUnit(NSCalendarUnit.Minute, value: min, toDate: next, options: [])!
                return next
            }
            
            // Caculate interval based on last dose
            if let lastDose = lastDose {
                // If overdue, return
                if isOverdue().flag {
                    return isOverdue().lastDose
                } else {
                    var next = cal.dateByAddingUnit(NSCalendarUnit.Hour, value: hr, toDate: lastDose.date, options: [])!
                    next = cal.dateByAddingUnit(NSCalendarUnit.Minute, value: min, toDate: next, options: [])!
                    return next
                }
            }
        case .Daily:
            guard let alarm = intervalAlarm else {
                throw MedicineError.NoAlarm
            }
            
            // Calculate interval from date provided
            if let date = date {
                let components = cal.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: alarm)
                let date = cal.dateBySettingHour(components.hour, minute: components.minute, second: 0, ofDate: date, options: [])!
                return cal.dateByAddingUnit(NSCalendarUnit.Day, value: Int(interval), toDate: date, options: [])
            }
            
            // Caculate interval based on last dose
            let components = cal.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: alarm)
            var date = cal.dateBySettingHour(components.hour, minute: components.minute, second: 0, ofDate: NSDate(), options: [])!
            
            if date.compare(NSDate()) == .OrderedAscending {
                date = cal.dateByAddingUnit(NSCalendarUnit.Day, value: Int(interval), toDate: date, options: [])!
            }
            
            return date
        default: break
        }
        
        return nil
    }
    
}


// MARK: - NSDate extensions

extension NSDate {

    // Determines if time is set to midnight
    func isMidnight() -> Bool {
        let cal = NSCalendar.currentCalendar()
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
        let cal = NSCalendar.currentCalendar()
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
        let cal = NSCalendar.currentCalendar()
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


// MARK: - Errors Enum
enum MedicineError: ErrorType {
    case InvalidName
    case TooSoon
    case DatePassed
    case ReminderDisabled
    case NoAlarm
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
