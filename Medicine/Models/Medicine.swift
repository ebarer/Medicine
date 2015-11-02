//
//  Medicine.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-28.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData
import CoreSpotlight
import MobileCoreServices

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
    
    @available(iOS 9.0, *)
    var attributeSet: CSSearchableItemAttributeSet? {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeContent as String)
        attributeSet.title = self.name!
        
        let dose = String(format:"%g %@", self.dosage, self.dosageUnit.units(self.dosage))
        
        if self.isOverdue().flag {
            let descriptionString = "Overdue\n\(dose)"
            attributeSet.contentDescription = descriptionString
        } else if let date = self.lastDose?.next {
            let descriptionString = "Next dose: \(Medicine.dateString(date))\n\(dose)"
            attributeSet.contentDescription = descriptionString
        } else {
            let descriptionString = "\(dose)"
            attributeSet.contentDescription = descriptionString
        }
        
        return attributeSet
    }
    
    var adherenceScore: Int? {
        if let tempArr = self.history?.array where tempArr.count > 0 {
            // Retrieve history
            var scoreArray = tempArr as! [History]
            
            // Reverse so newest items are at the top
            scoreArray = scoreArray.reverse()
            
            var averageScore: Int = 0
            var averageCount: Int = 0
            let historyLength = (scoreArray.count < 16) ? (scoreArray.count - 1) : 15
            
            switch(intervalUnit) {
            case .Hourly:
                return nil
//                    for i in 0...historyLength {
//                        if let expectedDate = scoreArray[i+1].next {
//                            let scoreDate = scoreArray[i].date
//                            if cal.isDate(scoreDate, inSameDayAsDate: expectedDate) {
//                                print("\(scoreArray[i].date) ? \(expectedDate)")
//                            }
//                        }
//                    }
            case .Daily:
                if let alarm = intervalAlarm {
                    let alarmComponents = cal.components([.Hour, .Minute], fromDate: alarm)
                    for i in 0...historyLength {
                        let date = scoreArray[i].date
                        let dateComponents = cal.components([.Hour, .Minute], fromDate: date)
                        let dif = cal.components(.Minute, fromDateComponents: dateComponents, toDateComponents: alarmComponents, options: [])
                        
                        print("\(name!): \(scoreArray[i].date) : \(dif.minute) = \(calculateScore(dif.minute, date: date))")
                        let (score, multiplier) = calculateScore(dif.minute, date: date)
                        averageScore += (score * multiplier)
                        averageCount += multiplier
                    }
                }
            default:
                return nil
            }
            
            print("\(name!) Score: \(averageScore / averageCount)")
            return (averageScore / averageCount)
        }

        return nil
    }
    
    func calculateScore(dif: Int, date: NSDate) -> (Score: Int, Multiplier: Int) {
        var score: Int = 0
        var multiplier: Int = 1
        
        switch(abs(dif)) {
        case 0...5:
            score = 100
        case 5...10:
            score = 75
        case 10...30:
            score = 50
        default:
            score = 0
        }
        
        if date.isDateInWeek() {
            multiplier = 3
        } else if date.isDateInLastWeek() {
            multiplier = 2
        }
        
        return (score, multiplier)
    }
    
    func isOverdue() -> (flag: Bool, lastDose: NSDate?) {
        // Medicine can't be overdue if reminders are disabled
        if reminderEnabled == true {
            switch(intervalUnit) {
            case .Hourly:
                if let date = lastDose?.next {
                    if date.compare(NSDate()) == .OrderedAscending {
                        return (true, date)
                    }
                }
            case .Daily:
                if let alarm = intervalAlarm {
                    
                    // If created today (with no history), overdue depends on alarm
                    if cal.isDateInToday(alarm) && lastDose == nil{
                        if alarm.compare(NSDate()) == .OrderedAscending{
                            return (true, nil)
                        }
                    }
                    
                    // If date is in today but behind the current time, return true
                    else if let date = lastDose?.next {
                        if cal.isDateInToday(date) && date.compare(NSDate()) == .OrderedAscending {
                            return (true, nil)
                        }
                        
                        // If in the passed and not scheduled for today, return true
                        if let scheduledDate = scheduledNotification?.fireDate {
                            if date.compare(NSDate()) == .OrderedAscending && !cal.isDateInToday(scheduledDate) {
                                return (true, nil)
                            }
                        }
                    }
                }
            default:
                return (false, nil)
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
    
    class func sortByNextDose(medA: Medicine, medB: Medicine) -> Bool {
        // Unscheduled medications should be at the bottom
        if medA.reminderEnabled == false {
            return false
        }
        
        if medB.reminderEnabled == false {
            return true
        }
        
        // Overdue medications should be at the top
        if medA.isOverdue().flag == true {
            return true
        }
        
        if medB.isOverdue().flag == true {
            return false
        }
        
        guard let next1 = medA.nextDose else {
            return false
        }
        
        guard let next2 = medB.nextDose else {
            return true
        }
        
        return next1.compare(next2) == .OrderedAscending
    }
    
    class func sortByManual(medA: Medicine, medB: Medicine) -> Bool {
        return medA.sortOrder < medB.sortOrder
    }
    
    class func dateString(date: NSDate?) -> String {
        guard let date = date else { return "" }
        
        let cal = NSCalendar.currentCalendar()
        let dateFormatter = NSDateFormatter()
        var dateString = String()
        
        // Set label date, skip if date is today
        if !cal.isDateInToday(date) {
            if cal.isDateInYesterday(date) {
                dateString = "Yesterday, "
            } else if cal.isDateInTomorrow(date) {
                dateString = "Tomorrow, "
            } else if date.isDateInWeek() {
                dateFormatter.dateFormat = "EEEE, "
                dateString = dateFormatter.stringFromDate(date)
            } else {
                // Default case
                dateFormatter.dateFormat = "MMM d, "
                dateString = dateFormatter.stringFromDate(date)
            }
        }
        
        // Set label time
        if date.isMidnight() {
            dateString.appendContentsOf("Midnight")
        } else {
            dateFormatter.dateFormat = "h:mm a"
            dateString.appendContentsOf(dateFormatter.stringFromDate(date))
        }
        
        return dateString
    }
    
    
    // MARK: - Initialization method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        if self.medicineID.isEmpty {
            self.medicineID = NSUUID().UUIDString
        }
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
    
    func addDose(moc: NSManagedObjectContext, date doseDate: NSDate, dosage: Float? = nil, dosageUnitInt: Int16? = nil) -> History {
        // Log current dosage as new history element
        let entity = NSEntityDescription.entityForName("History", inManagedObjectContext: moc)
        
        let newDose = History(entity: entity!, insertIntoManagedObjectContext: moc)
        newDose.medicine = self
        newDose.date = doseDate

        if let dosage = dosage {
            newDose.dosage = dosage
        } else {
            newDose.dosage = self.dosage
        }
        
        if let dosageUnitInt = dosageUnitInt {
            newDose.dosageUnitInt = dosageUnitInt
        } else {
            newDose.dosageUnitInt = self.dosageUnitInt
        }
        
        do {
            newDose.next = try calculateNextDose(doseDate)
        } catch {
            newDose.next = nil
        }
        
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
            let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
            delegate.saveContext()
            
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
        cancelNotification()
        
        guard let date = nextDose else { return false }
        
        do {
            try scheduleNotification(date)
            return true
        } catch {
            return false
        }
    }
    
    func snoozeNotification() -> Bool {
        let defaults = NSUserDefaults(suiteName: "group.com.ebarer.Medicine")!
        var snoozeDate = NSDate()
        
        // Set snooze delay to user selection or 5 minutes
        if defaults.valueForKey("snoozeLength") != nil {
            let val = defaults.valueForKey("snoozeLength") as! Int
            snoozeDate = cal.dateByAddingUnit(NSCalendarUnit.Minute, value: val, toDate: NSDate(), options: [])!
        } else {
            snoozeDate = cal.dateByAddingUnit(NSCalendarUnit.Minute, value: 5, toDate: NSDate(), options: [])!
        }
        
        // Update last dose next value in case notifications are rescheduled
        self.lastDose?.next = snoozeDate
        
        // Schedule new notification
        do {
            cancelNotification()
            try scheduleNotification(snoozeDate)
            return true
        } catch {
            return false
        }
    }
    
    func cancelNotification() {
        let notifications = UIApplication.sharedApplication().scheduledLocalNotifications!
        for notification in notifications {
            let (id, _) = (notification.userInfo?["id"] as? String, notification.userInfo?["snooze"] as? Bool)
            if (id == self.medicineID) {
                UIApplication.sharedApplication().cancelLocalNotification(notification)
            }
        }
    }
    
    
    // MARK: - Helper method
    func calculateNextDose(date: NSDate? = nil) throws -> NSDate? {
        switch(intervalUnit) {
        case .None:
            return nil
        case .Hourly:
            let hr = Int(interval)
            let min = Int(60 * (interval % 1))
            
            // Calculate interval from date provided
            if let date = date {
                var next = cal.dateByAddingUnit(NSCalendarUnit.Hour, value: hr, toDate: date, options: [])!
                next = cal.dateByAddingUnit(NSCalendarUnit.Minute, value: min, toDate: next, options: [])!
                return next
            }
            
            // Calculate interval based on last dose
            if let lastDose = lastDose {
                // If next dose is in the future, return next dose
                if lastDose.next?.compare(NSDate()) == .OrderedDescending {
                    return lastDose.next
                }
                    
                // If med is overdue
                else if isOverdue().flag {
                    return isOverdue().lastDose
                }
                
                else {
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
            
            // Handle snooze
            if let date = lastDose?.next {
                if cal.isDateInToday(date) && date.compare(NSDate()) == .OrderedDescending {
                    return lastDose?.next
                }
            }
            
            // Calculate interval based on last dose
            var date = alarm
            let components = cal.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: alarm)
            
            // If no last dose
            if lastDose?.date == nil {
                date = cal.dateBySettingHour(components.hour, minute: components.minute, second: 0, ofDate: NSDate(), options: [])!
                
                while date.compare(NSDate()) == .OrderedAscending {
                    date = cal.dateByAddingUnit(NSCalendarUnit.Day, value: 1, toDate: date, options: [])!
                }

                return date
            }
            
            // If last dose was today, schedule for next interval
            if let last = lastDose?.date where cal.isDateInToday(last) {
                date = cal.dateBySettingHour(components.hour, minute: components.minute, second: 0, ofDate: last, options: [])!
                date = cal.dateByAddingUnit(NSCalendarUnit.Day, value: Int(interval), toDate: date, options: [])!
            }
            
            // If scheduled dose is in the past, schedule for next interval until it is for the future
            while date.compare(NSDate()) == .OrderedAscending {
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


// MARK: - Sort Order Enum
enum SortOrder: Int {
    case Manual
    case NextDosage
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
    case None = -1
    case Hourly = 0
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
        default: return "None"
        }
    }
    
    func units(amount: Float?) -> String {
        var string = ""
        
        switch self {
        case .Hourly: string = "hour"
        case .Daily: string = "day"
        case .Weekly: string = "week"
        default: string = "none"
        }
        
        if (amount < 1 || amount >= 2) {
            string += "s"
        }
        
        return string
    }

}
