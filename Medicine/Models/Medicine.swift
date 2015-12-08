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

    var lastDose: Dose? {
        if let lastHistory = doseHistory {
            if let object = lastHistory.firstObject {
                var dose = object as! Dose
                
                for next in lastHistory.array as! [Dose] {
                    // Ignore if item is set to be deleted
                    if (!next.deleted && dose.date.compare(next.date) == .OrderedAscending) {
                        dose = next
                    }
                }
                
                return dose
            }
        }
        
        return nil
    }
    
    var scheduledNotifications: [UILocalNotification]? {
        var medNotifications = [UILocalNotification]()
        
        let notifications = UIApplication.sharedApplication().scheduledLocalNotifications!
        for notification in notifications {
            if let id = notification.userInfo?["id"] as? String {
                if (id == self.medicineID) {
                    medNotifications.append(notification)
                }
            }
        }
        
        if medNotifications.count == 0 {
            return nil
        }
        
        return medNotifications
    }
    
    func doseArray() -> [NSDate: [Dose]]? {
        if self.doseHistory?.count > 0 {
            var arr = [NSDate: [Dose]]()
            for dose in self.doseHistory?.array as! [Dose] {
                let date = cal.startOfDayForDate(dose.date)
                if (arr[date] == nil) {
                    arr[date] = []
                }
                arr[date]!.append(dose)
            }
            
            // return sorted(g.keys) { (a: NSDate, b: NSDate) in
            //     a.compare(b) == .OrderedAscending // sorting the outer array by 'time'
            // }
            // sorting the inner arrays by 'name'
            // .map { sorted(g[$0]!) { $0.name < $1.name } }
            
            return arr
        }
        
        return nil
    }
    
    /**
     Display the interval as a properly formatted string
     
     - Returns: Formatted interval string
     */
    func intervalLabel() -> String {
        var label = String()
        
        let hr = Int(self.interval)
        let min = Int(60 * (self.interval % 1))
        let hrUnit = self.intervalUnit.units(self.interval)
        
        if hr == 1 && min == 0 {
            label = String(format:"%@", hrUnit.capitalizedString)
        } else if min == 0 {
            label = String(format:"%d %@", hr, hrUnit)
        } else if hr == 0 {
            label = String(format:"%d min", min)
        } else {
            label = String(format:"%d %@ %d min", hr, hrUnit, min)
        }
        
        // Append alarm time for daily interval
        if self.intervalUnit == .Daily {
            if let alarm = self.intervalAlarm {
                if alarm.isMidnight() {
                    label += " at Midnight"
                } else {
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
                    dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
                    
                    label += String(format:" at %@", dateFormatter.stringFromDate(alarm))
                }
            }
        }
        
        return label
    }

    /**
     Determines how well the user is adhering to their dose schedule
     Scored on a 100 point scale
     
     - Returns: Score as Int, or nil if not enough history
     */
    func adherenceScore() -> Int? {
        if let tempArr = self.doseHistory?.array where tempArr.count > 0 {
            // Retrieve history
            var scoreArray = tempArr as! [Dose]
            
            // Reverse so newest items are at the top
            scoreArray = scoreArray.reverse()
            
            var averageScore: Int = 0
            var averageCount: Int = 0
            let historyLength = (scoreArray.count <= 14) ? (scoreArray.count - 1) : 14
            
            switch(intervalUnit) {
            case .Hourly:
                for i in 0...historyLength {
                    if let expectedDate = scoreArray[i].expectedDate {
                        let date = scoreArray[i].date
                        let dateComponents = cal.components([.Hour, .Minute], fromDate: date)
                        let expectedComponents = cal.components([.Hour, .Minute], fromDate: expectedDate)
                        
                        // Get difference
                        let dif = cal.components(.Minute, fromDateComponents: expectedComponents, toDateComponents: dateComponents, options: [])
                        
                        // Determine score
                        if let (score, multiplier) = calculateScore(dif.minute, date: date) {
                            averageScore += (score * multiplier)
                            averageCount += multiplier
                        }
                    }
                }
            case .Daily:
                if let alarm = intervalAlarm {
                    let alarmComponents = cal.components([.Hour, .Minute], fromDate: alarm)
                    for i in 0...historyLength {
                        let date = scoreArray[i].date
                        let dateComponents = cal.components([.Hour, .Minute], fromDate: date)
                        
                        // Get difference
                        let dif = cal.components(.Minute, fromDateComponents: alarmComponents, toDateComponents: dateComponents, options: [])
                        
                        // Determine score
                        if let (score, multiplier) = calculateScore(dif.minute, date: date) {
                            averageScore += (score * multiplier)
                            averageCount += multiplier
                        }
                    }
                }
            default:
                return nil
            }
            
            if averageCount == 0 { return nil }
            return (averageScore / averageCount)
        }

        return nil
    }
    
    func calculateScore(dif: Int, date: NSDate) -> (Score: Int, Multiplier: Int)? {
        var score: Int = 0
        var multiplier: Int = 1
        
        switch(abs(dif)) {
        case let x where x == 0:
            score = 100
        case let x where x > -10 && x < 10:
            score = 75
        case let x where x > -30 && x < 30:
            score = 50
        case let x where x > -60 && x < 60:
            score = 0
        default:
            return nil
        }
        
        if date.isDateInWeek() {
            multiplier = 3
        } else if date.isDateInLastWeek() {
            multiplier = 2
        }
        
        return (score, multiplier)
    }
    
    /**
     Determines whether the medication is overdue
     
     - Returns: Tuple: (Overdue value as Bool, NSDate of overdue dose)
     */
    func isOverdue() -> (flag: Bool, overdueDose: NSDate?) {
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
                            return (true, alarm)
                        }
                    }
                    
                    // If date is in today but behind the current time, return true
                    else if let date = lastDose?.next {
                        if cal.isDateInToday(date) && date.compare(NSDate()) == .OrderedAscending {
                            return (true, date)
                        }
                        
                        // If in the past and not scheduled for today, return true
                        if let scheduledDate = scheduledNotifications?.first?.fireDate {
                            if date.compare(NSDate()) == .OrderedAscending && !cal.isDateInToday(scheduledDate) {
                                return (true, scheduledDate)
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
    
    
    // MARK: - Spotlight indexing values
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
            if medB.reminderEnabled == false {
                // If both are unscheduled, return sorted by name
                return medA.name!.compare(medB.name!) == .OrderedAscending
            }
            
            return false
        } else if medB.reminderEnabled == false {
            return true
        }
        
        // Overdue medications should be at the top
        if medA.isOverdue().flag == true {
            if let overdue2 = medB.isOverdue().overdueDose {
                if let overdue1 = medA.isOverdue().overdueDose {
                    // If both are overdue, return sorted by longest overdue
                    return overdue1.compare(overdue2) == .OrderedAscending
                }
                
                return false
            }
            
            return true
        } else if medB.isOverdue().flag == true {
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
    
    class func dateString(date: NSDate?, today: Bool = true) -> String {
        guard let date = date else { return "" }
        
        let cal = NSCalendar.currentCalendar()
        let dateFormatter = NSDateFormatter()
        var dateString = String()
        
        // Set label date, skip if date is today (parameter)
        if today == true && cal.isDateInToday(date) {
            dateString = "Today, "
        } else if !cal.isDateInToday(date) {
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
            if cal.isDateInTomorrow(date) {
                dateString = "Midnight"
            } else if cal.isDateInToday(date) {
                dateString = "Yesterday, Midnight"
            } else {
                dateString.appendContentsOf("Midnight")
            }
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
    
    
    // MARK: - Dose methods
    
    /**
    Add a new dose for medication
    
    - Parameter dose: History object
    
    - Throws: 'MedicineError.TooSoon' if another dose has been taken in the previous 5 minutes.
    */
    func takeDose(dose: Dose) throws {
        // Only check for duplicate if attempting to take new dose
        if lastDose?.date.compare(dose.date) == .OrderedAscending {
            
            // Throw error if another dose has been taken within the previous 5 minutes
            let compareDate = cal.dateByAddingUnit(NSCalendarUnit.Minute, value: -5, toDate: dose.date, options: [])!
            
            if lastDose != nil {
                guard lastDose?.date.compare(compareDate) == .OrderedAscending else {
                    throw MedicineError.TooSoon
                }
            }
        }
        
        addDose(dose)
    }
    
    /**
     Add a new dose for medication
     
     - Parameter dose: History object
     
     - Returns: History object
     */
    func addDose(dose: Dose) -> Dose {
        // Calculate the next dose and store in dose
        do {
            dose.next = try calculateNextDose(dose.date)
        } catch {
            dose.next = nil
        }
        
        // Get expected date and store in dose
        if let lastDose = lastDose where lastDose.date.compare(dose.date) == .OrderedAscending {
            if let expected = lastDose.next {
                dose.expectedDate = expected
            } else {
                do {
                    dose.expectedDate = try calculateNextDose(lastDose.date)
                } catch {
                    dose.expectedDate = nil
                }
            }
        }
        
        // Modify prescription count
        if self.refillHistory?.count > 0 {
            if self.prescriptionCount < dose.dosage {
                self.prescriptionCount = 0
            } else {
                self.prescriptionCount -= dose.dosage
            }
        }
        
        // Reschedule notification if dose is medications only/latest dose
        if self.lastDose == nil || dose.date.compare(self.lastDose!.date) == .OrderedDescending {
            scheduleNextNotification()
        }
        
        return dose
    }

    /**
     Remove the last dose for medication
     
     - Parameter moc: NSManagedObjectContext object
     
     - Returns: Bool depending on whether action was successful
     */
    func untakeLastDose(moc: NSManagedObjectContext) -> Bool {
        if let lastDose = lastDose {
            untakeDose(lastDose, moc: moc)
            
            scheduleNextNotification()
            return true
        }
        
        return false
    }

    /**
     Remove a dose from medication history

     - Parameter dose: History object
     - Parameter moc: NSManagedObjectContext object
     */
    func untakeDose(dose: Dose, moc: NSManagedObjectContext) {
        // Modify prescription count
        if self.refillHistory?.count > 0 {
            // Only enable refill flag if undoing the dosage puts count in excess
            if needsRefill() == false {
                self.refillFlag = true
            }
            
            self.prescriptionCount += dose.dosage
        }
        
        moc.deleteObject(dose)
        
        // Save dose deletion
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        delegate.saveContext()
    }
    
    
    // MARK: - Prescription methods
    /**
    Add a new prescription refill for medication
    
    - Parameter moc: Managed object context
    - Parameter date: Date when refill occurred/should be logged
    - Parameter refillQuantity: Amount of medication in refill
    
    - Returns: Prescription element for refill
    */
    func addRefill(refill: Refill) {
        // Increase prescription count
        self.prescriptionCount += refill.quantity * refill.conversion
        self.refillFlag = true
    }
    
    /**
     Add a new prescription refill for medication
     
     - Parameter moc: Managed object context
     - Parameter date: Date when refill occurred/should be logged
     - Parameter refillQuantity: Amount of medication in refill
     
     - Returns: Prescription element for refill
     */
    func removeRefill(refill: Refill, moc: NSManagedObjectContext) {
        // Increase prescription count
        let amount = refill.quantity * refill.conversion
        if self.prescriptionCount < amount {
            self.prescriptionCount = 0
        } else {
            self.prescriptionCount -= amount
        }
        
        moc.deleteObject(refill)
        
        // Save refill deletion
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        delegate.saveContext()
    }

    /**
     Determine number of days worth of prescription remaining
     
     - Returns: Int: number of days remaining
    */
    func refillDaysRemaining() -> Int? {
        // Only calculate if there is a prescription refill history
        if self.prescriptionCount > 0 {
            if let history = self.doseArray() {
                // Only calculate the daily consumption average
                // when medication has more than a week of data
                if history.count >= 7  {
                    // Determine total amount of medication consumed
                    var doseCount: Float = 0.0
                    for i in history {
                        for j in i.1 {
                            doseCount += j.dosage
                        }
                    }
                    
                    // Calculate daily consumption average
                    let dailyAvg = round(doseCount / Float(history.count))
                    
                    // Calculate number of days remaining
                    let days = Int(floorf(self.prescriptionCount / dailyAvg))
                    
                    return days
                }
            }
            
            if intervalUnit == Intervals.Daily {
                let days = Int(floorf(prescriptionCount * (interval / dosage)))
                return days
            }
        }
        
        return nil
    }
    
    /**
     Determine whether the medication needs to be refilled
     
     - Parameter limit: Number of days worth of prescription remaining (default is 3 days)
     
     - Returns: Bool indicating whether user needs to be notified to refill
    */
    func needsRefill(limit limit: Int = 3) -> Bool {
        if self.refillHistory?.count > 0 {
            if let days = refillDaysRemaining() where days <= limit {
                return true
            }
            
            if prescriptionCount < dosage {
                return true
            }
        }
        
        return false
    }

    /**
     Return formatted refill status
     
     - Parameter newMed: Bool representing whether this is a new medication
     
     - Returns: String with refill status
     */
    func refillStatus(entry entry: Bool = false, conversion: Bool = false) -> String {
        var status = ""
        
        // If new medication with prescription count of 0
        if entry && prescriptionCount == 0 {
            if refillHistory?.count == 0 {
                status = "Enter your prescription amount below. "
                
                if !conversion {
                    status += "If you receive your prescription in a different unit, you will need to enter a conversion amount (ie. Milligrams/Pill). "
                }
            } else {
                status = "You do not currently have any \(name!). "
            }
        }
        
        // If medication has no refill history
        else if !entry && refillHistory?.count == 0 {
            status = "Tap \"Refill Prescription\" to update your prescription amount. "
        }
            
        // If prescription count is insufficient for dosage
        else if !entry && prescriptionCount < dosage {
            status = "You do not appear to have enough \(name!) remaining to take this dose. "
            status += "Tap \"Refill Prescription\" to update your prescription amount. "
        }
        
        else {
            status = "You currently have "
            status += "\(removeTrailingZero(prescriptionCount)) \(dosageUnit.units(prescriptionCount)) of \(name!). "
            
            if let days = refillDaysRemaining() where !entry {
                if days <= 1 {
                    status += "You will need to refill after this dose. "
                } else {
                    status += "Based on your current usage, this will last you approximately \(days) \(Intervals.Daily.units(Float(days))). "
                }
            }
        }
        
        return status
    }
    
    
    // MARK: - Notification methods
    func scheduleNotification(date: NSDate, badgeCount: Int = 1) throws {
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
        notification.alertAction = "View Medicine"
        notification.alertTitle = "Take \(name)"
        notification.alertBody = String(format:"Time to take %g %@ of %@", dosage, dosageUnit.units(dosage), name)
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.category = "Dose Reminder"
        notification.userInfo = ["id": self.medicineID]
        notification.applicationIconBadgeNumber = badgeCount
        notification.fireDate = date
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    func scheduleNextNotification() -> Bool {
        cancelNotification()
        
        guard let date = nextDose else { return false }
        
        do {
            try scheduleNotification(date, badgeCount: getBadgeCount(date))
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
        
        // Save modifications to last dose
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        delegate.saveContext()
        
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
    
    func sendRefillNotification() {
        if prescriptionCount < dosage || refillFlag {
            let notification = UILocalNotification()
            
            var message = "You are running low on \(name!) and should refill soon."
            
            if prescriptionCount < dosage {
                message = "You don't have enough \(name!) to take your next dose."
            } else if let count = refillDaysRemaining() where prescriptionCount > 0 && count > 0 {
                message = "You currently have enough \(name!) for about \(count) \(count == 1 ? "day" : "days") and should refill soon."
            }
            
            notification.alertTitle = "Refill \(name!)"
            notification.alertBody = message
            notification.soundName = UILocalNotificationDefaultSoundName
            notification.category = "Refill Reminder"
            notification.userInfo = ["id": self.medicineID, "type": "refill"]
            notification.fireDate = NSDate()
            
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
            
            refillFlag = false
        }
    }
    
    
    // MARK: - Helper method
    
    /**
    Determine the number of overdue items at a specific date
    
    - Parameter date: Date at which to determine overdue count
    
    - Returns: Number of overdue items at date
    */
    func getBadgeCount(date: NSDate) -> Int {
        return medication.filter({$0.nextDose?.compare(date) != .OrderedDescending}).count
    }
    
    /**
    Determine the date of the next dose from the current time or optional parameter
    
    - Parameter date: Optional date from which to calculate
    
    - Returns: Date of next dose or nil
    
    - Throws: 'MedicineError.NoAlarm' if medication has daily interval and no alarm set
    */
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
                    return isOverdue().overdueDose
                }
                    
                // If reminders are disable
                else if reminderEnabled == false {
                    return lastDose.next
                }
                
                // Calculate next dose based on last dose taken, and update next value
                else {
                    var next = lastDose.date
                    while next.compare(NSDate()) == .OrderedAscending {
                        next = cal.dateByAddingUnit(NSCalendarUnit.Hour, value: hr, toDate: next, options: [])!
                        next = cal.dateByAddingUnit(NSCalendarUnit.Minute, value: min, toDate: next, options: [])!
                    }
                    
                    lastDose.next = next
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
            
            // Return pre-calculated next dose and handle snooze
            if let date = lastDose?.next {
                if date.compare(NSDate()) == .OrderedDescending {
                    return lastDose?.next
                }
            }
            
            var date = alarm
            let components = cal.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: alarm)
            
            // If no last dose
            if lastDose?.date == nil {
                date = cal.dateBySettingHour(components.hour, minute: components.minute, second: 0, ofDate: NSDate(), options: [])!
                
                while date.compare(NSDate()) == .OrderedAscending && cal.isDateInToday(date) == false {
                    date = cal.dateByAddingUnit(NSCalendarUnit.Day, value: 1, toDate: date, options: [])!
                }

                return date
            }
            // If scheduled dose is in the past, schedule for next interval until it is for the future
            else if let last = lastDose?.date {
                date = cal.dateBySettingHour(components.hour, minute: components.minute, second: 0, ofDate: last, options: [])!
                
                while date.compare(NSDate()) == .OrderedAscending && cal.isDateInToday(date) == false {
                    date = cal.dateByAddingUnit(NSCalendarUnit.Day, value: Int(interval), toDate: date, options: [])!
                }
                
                if lastDose?.next?.compare(NSDate()) == .OrderedAscending {
                    lastDose?.next = date
                }
            }
            
            return date
        default: break
        }
        
        return nil
    }
    
    /**
     Removes trailing zeroes from passed number
     
     Parameter num: Float value to truncate
     
     Returns: Number as a string with trailing zeroes truncated
     */
    func removeTrailingZero(num: Float) -> String {
        return String(format: "%g", num)
    }
    
}


// MARK: - NSDate extension
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
    
//    public override var description : String {
//        let dateFormatter = NSDateFormatter()
//        dateFormatter.timeZone = NSTimeZone.systemTimeZone()
//        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
//        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
//        return dateFormatter.stringFromDate(self)
//    }
    
}


// MARK: - Array extension
extension Array {
    mutating func removeObject<U: Equatable>(object: U) {
        for (index, compare) in self.enumerate() {
            if let compare = compare as? U {
                if object == compare {
                    self.removeAtIndex(index)
                    break
                }
            }
        }
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