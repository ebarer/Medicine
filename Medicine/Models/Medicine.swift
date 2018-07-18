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
import UserNotifications

class Medicine: NSManagedObject {
    
    // MARK: - Enum variables
    fileprivate let cal = Calendar.current
    
    var dosageUnit: Doses {
        get { return Doses(rawValue: self.dosageUnitInt)! }
        set { self.dosageUnitInt = newValue.rawValue }
    }
    
    var intervalUnit: Intervals {
        get { return Intervals(rawValue: self.intervalUnitInt)! }
        set { self.intervalUnitInt = newValue.rawValue }
    }
    

    // MARK: - Member variables
    var nextDose: Date? {
        guard let date = try? calculateNextDose() else {
            self.hasNextDose = false
            self.dateNextDose = nil
            return nil
        }

        // For as needed medication, if their next dose is in the past,
        // push it into the future to ensure correct sorting
        if (self.reminderEnabled == false) && (date?.compare(Date()) == .orderedAscending) {
            self.hasNextDose = false
            self.dateNextDose = nil
        } else {
            self.hasNextDose = (date != nil)
            self.dateNextDose = date
        }
        
        // Ensure new medications are at top of sort (for hourly)
        if self.doseHistory?.count == 0 && self.hasNextDose == false {
            self.isNew = true
        } else {
            self.isNew = false
        }
        
        return date
    }
    
    var lastDose: Dose? {
        guard let history = doseHistory?.array as? [Dose] else {
            self.dateLastDose = nil
            return nil
        }
        
        guard let dose = history.sorted(by: { $0.date.compare($1.date) == .orderedDescending }).first else {
            self.dateLastDose = nil
            return nil
        }
        
        self.dateLastDose = dose.date
        return dose
    }
    
    func doseArray() -> [Date: [Dose]]? {
        guard let doseCount = self.doseHistory?.count else {
            return nil
        }
        
        if doseCount > 0 {
            var arr = [Date: [Dose]]()
            for dose in self.doseHistory?.array as! [Dose] {
                let date = cal.startOfDay(for: dose.date as Date)
                if (arr[date] == nil) {
                    arr[date] = []
                }
                arr[date]!.append(dose)
            }
            
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
        let min = Int(60 * (self.interval.truncatingRemainder(dividingBy: 1)))
        let hrUnit = self.intervalUnit.units(self.interval)
        
        if hr == 1 && min == 0 {
            label = String(format:"%@", hrUnit.capitalized)
        } else if min == 0 {
            label = String(format:"%d %@", hr, hrUnit)
        } else if hr == 0 {
            label = String(format:"%d min", min)
        } else {
            label = String(format:"%d %@ %d min", hr, hrUnit, min)
        }
        
        // Append alarm time for daily interval
        if self.intervalUnit == .daily {
            if let alarm = self.intervalAlarm {
                if alarm.isMidnight() {
                    label += " at Midnight"
                } else {
                    let dateFormatter = DateFormatter()
                    dateFormatter.timeStyle = DateFormatter.Style.short
                    dateFormatter.dateStyle = DateFormatter.Style.none
                    label += String(format:" at %@", dateFormatter.string(from: alarm as Date))
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
        if let tempArr = self.doseHistory?.array, tempArr.count > 0 {
            // Retrieve history
            var scoreArray = tempArr as! [Dose]
            
            // Reverse so newest items are at the top
            scoreArray = scoreArray.reversed()
            
            var averageScore: Int = 0
            var averageCount: Int = 0
            let historyLength = (scoreArray.count <= 14) ? (scoreArray.count - 1) : 14
            
            switch(intervalUnit) {
            case .hourly:
                for i in 0...historyLength {
                    if let expectedDate = scoreArray[i].expectedDate {
                        let date = scoreArray[i].date
                        let dateComponents = (cal as NSCalendar).components([.hour, .minute], from: date as Date)
                        let expectedComponents = (cal as NSCalendar).components([.hour, .minute], from: expectedDate as Date)
                        
                        // Get difference
                        let dif = (cal as NSCalendar).components(.minute, from: expectedComponents, to: dateComponents, options: [])
                        
                        // Determine score
                        if let (score, multiplier) = calculateScore(dif.minute!, date: date as Date) {
                            averageScore += (score * multiplier)
                            averageCount += multiplier
                        }
                    }
                }
            case .daily:
                if let alarm = intervalAlarm {
                    let alarmComponents = (cal as NSCalendar).components([.hour, .minute], from: alarm as Date)
                    for i in 0...historyLength {
                        let date = scoreArray[i].date
                        let dateComponents = (cal as NSCalendar).components([.hour, .minute], from: date as Date)
                        
                        // Get difference
                        let dif = (cal as NSCalendar).components(.minute, from: alarmComponents, to: dateComponents, options: [])
                        
                        // Determine score
                        if let (score, multiplier) = calculateScore(dif.minute!, date: date as Date) {
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
    
    func calculateScore(_ dif: Int, date: Date) -> (Score: Int, Multiplier: Int)? {
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
    func isOverdue() -> (flag: Bool, overdueDose: Date?) {
        // Medicine can't be overdue if reminders are disabled
        if reminderEnabled == true {
            do {
                let date = try calculateNextDose()
                if date?.compare(Date()) == .orderedAscending {
                    return (true, date)
                } else {
                    return (false, date)
                }
            } catch {
                NSLog("Couldn't determine if \(name ?? "unknown medicine") is overdue; unable to calculate next dose.")
                return (false, nil)
            }
        }
        
        return (false, nil)
    }
    
    
    // MARK: - Spotlight indexing values
    var attributeSet: CSSearchableItemAttributeSet? {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeContent as String)
        if let name = self.name {
            attributeSet.title = name
            
            let dose = String(format:"%g %@", self.dosage, self.dosageUnit.units(self.dosage))
            
            if self.isOverdue().flag {
                let descriptionString = "Overdue\n\(dose)"
                attributeSet.contentDescription = descriptionString
            } else if let date = self.lastDose?.next {
                let descriptionString = "Next dose: \(Medicine.dateString(date as Date))\n\(dose)"
                attributeSet.contentDescription = descriptionString
            } else {
                let descriptionString = "\(dose)"
                attributeSet.contentDescription = descriptionString
            }
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
    
    class func sortByNextDose(_ medA: Medicine, medB: Medicine) -> Bool {
        // Unscheduled medications should be at the bottom
        if medA.reminderEnabled == false {
            if medB.reminderEnabled == false {
                // If both are unscheduled, return sorted by name
                return medA.name!.compare(medB.name!) == .orderedAscending
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
                    return overdue1.compare(overdue2) == .orderedAscending
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
        
        return next1.compare(next2) == .orderedAscending
    }
    
    class func sortByManual(_ medA: Medicine, medB: Medicine) -> Bool {
        return medA.sortOrder < medB.sortOrder
    }
    
    class func dateString(_ date: Date?, today: Bool = true) -> String {
        guard let date = date else { return "" }
        
        let cal = Calendar.current
        let dateFormatter = DateFormatter()
        var dateString = String()
        
        // Set label date, skip if date is today (parameter)
        if today == true && cal.isDateInToday(date) {
            dateString = "Today at "
        } else if !cal.isDateInToday(date) {
            if cal.isDateInYesterday(date) {
                dateString = "Yesterday at "
            } else if cal.isDateInTomorrow(date) {
                dateString = "Tomorrow at "
            } else if date.isDateInWeek() {
                dateString = date.string(withFormat: "EEEE") + " at "
            } else {
                // Default case
                dateFormatter.dateFormat = "MMM d"
                dateString = date.string(withFormat: "MMM d") + " at "
            }
        }
        
        // Set label time
        if date.isMidnight() {
            if cal.isDateInTomorrow(date) {
                dateString = "Midnight"
            } else if cal.isDateInToday(date) {
                dateString = "Yesterday at Midnight"
            } else {
                dateString.append("Midnight")
            }
        } else {
            dateString.append(date.string(withFormat: "h:mm a"))
        }
        
        return dateString
    }
    
    
    // MARK: - Initialization method
    convenience init(insertInto context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Medicine", in: context) {
            self.init(entity: entity, insertInto: context)
            
            if self.medicineID.isEmpty {
                self.medicineID = UUID().uuidString
                self.dateCreated = Date()
            }
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
    
    // MARK: - Dose methods
    
    /**
    Add a new dose for medication
    
    - Parameter dose: History object
    
    - Throws: 'MedicineError.TooSoon' if another dose has been taken in the previous 5 minutes.
    */
    func takeDose(_ dose: Dose) throws {
        // Only check for duplicate if attempting to take new dose
        if lastDose?.date.compare(dose.date as Date) == .orderedAscending {
            
            // Throw error if another dose has been taken within the previous 5 minutes
            let compareDate = (cal as NSCalendar).date(byAdding: NSCalendar.Unit.minute, value: -5, to: dose.date as Date, options: [])!
            
            if lastDose != nil {
                guard lastDose?.date.compare(compareDate) == .orderedAscending else {
                    throw MedicineError.tooSoon
                }
            }
        }
        
        addDose(dose)
    }

    @discardableResult func addDose(_ dose: Dose) -> Dose {
        dose.medicine = self
        
        // Calculate the next dose and store in dose
        // Need to calculate based on current dose time
        let nextDate = try? calculateNextDose(dose.date as Date)! as Date
        dose.next = nextDate
        self.hasNextDose = (nextDate != nil)
        self.dateNextDose = nextDate
        
        self.isNew = false
        
        // Get expected date and store in dose
        if let lastDose = lastDose, lastDose.date.compare(dose.date as Date) == .orderedAscending {
            if let expected = lastDose.next {
                dose.expectedDate = expected
            } else {
                do {
                    dose.expectedDate = try calculateNextDose(lastDose.date as Date)! as Date
                } catch {
                    dose.expectedDate = nil
                }
            }
        }
        
        // Modify prescription count
        if let refillCount = self.refillHistory?.count {
            if refillCount > 0 && dose.dosage > 0 {
                if self.prescriptionCount < dose.dosage {
                    self.prescriptionCount = 0
                    self.refillFlag = true
                } else {
                    self.prescriptionCount -= dose.dosage
                }
            }
        }
        
        // Reschedule notification if dose is medications only/latest dose
        if self.lastDose == nil || dose.date.compare(self.lastDose!.date as Date) != .orderedAscending {
            scheduleNextNotification()
        }
        
        return dose
    }
    
    /**
 
     */
    func skipDose(context: NSManagedObjectContext) {
        let dose = Dose(insertInto: context)
        dose.date = Date()
        dose.dosage = -1
        dose.dosageUnit = self.dosageUnit
        
        self.addDose(dose)
    }

    /**
     Remove the last dose for medication
     
     - Parameter moc: NSManagedObjectContext object
     
     - Returns: Bool depending on whether action was successful
     */
    @discardableResult func untakeLastDose(context: NSManagedObjectContext) -> Bool {
        if let lastDose = lastDose {
            untakeDose(lastDose, context: context)
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
    func untakeDose(_ dose: Dose, context: NSManagedObjectContext) {
        // Modify prescription count
        if let refillCount = self.refillHistory?.count {
            if (refillCount > 0) && (dose.dosage > 0) {
                // Only enable refill flag if undoing the dosage puts count in excess
                if needsRefill() == false {
                    self.refillFlag = true
                }
                
                self.prescriptionCount += dose.dosage
            }
        }
        
        context.delete(dose)
        
        // Update next and last dose values
        _ = self.nextDose
        _ = self.lastDose
    }
    
    
    // MARK: - Prescription methods
    /**
    Add a new prescription refill for medication
    
    - Parameter moc: Managed object context
    - Parameter date: Date when refill occurred/should be logged
    - Parameter refillQuantity: Amount of medication in refill
    
    - Returns: Prescription element for refill
    */
    func addRefill(_ refill: Refill) {
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
    func removeRefill(_ refill: Refill, moc: NSManagedObjectContext) {
        // Increase prescription count
        let amount = refill.quantity * refill.conversion
        if self.prescriptionCount < amount {
            self.prescriptionCount = 0
        } else {
            self.prescriptionCount -= amount
        }
        
        moc.delete(refill)
        
        // Save refill deletion
        let cdStack = (UIApplication.shared.delegate as! AppDelegate).stack
        cdStack.save()
    }

    /**
     Determine number of days worth of prescription remaining
     
     - Returns: Int: number of days remaining
    */
    func refillDaysRemaining() -> Int? {
        // Only calculate the daily consumption average
        // if there is a prescription refill history, and
        // the medication has more than a week of usage data
        guard self.prescriptionCount > 0,
            let history = self.doseArray(),
            history.count >= 7
        else {
            if intervalUnit == Intervals.daily {
                let days = Int(floorf(prescriptionCount * (interval / dosage)))
                return days
            } else {
                return nil
            }
        }

        // Determine total amount of medication consumed
        let doseCount = Array(history.values).reduce(0, { $0 + $1.reduce(0, { $0 + $1.dosage }) })
        
        // Calculate daily consumption average
        let dailyAvg = round(doseCount / Float(history.count))
        if dailyAvg == 0 { return nil }
        
        // Calculate number of days remaining
        let days = Int(floorf(self.prescriptionCount / dailyAvg))
        
        return days
    }
    
    /**
     Determine whether the medication needs to be refilled
     
     - Parameter limit: Number of days worth of prescription remaining (default is 3 days)
     
     - Returns: Bool indicating whether user needs to be notified to refill
    */
    func needsRefill(limit: Int = 3) -> Bool {
        if let refillCount = self.refillHistory?.count {
            if refillCount > 0 {
                if let days = refillDaysRemaining(), days <= limit {
                    return true
                }
                
                if prescriptionCount < dosage {
                    return true
                }
            }
        }
        
        return false
    }

    /**
     Return formatted refill status
     
     - Parameter newMed: Bool representing whether this is a new medication
     
     - Returns: String with refill status
     */
    func refillStatus(entry: Bool = false, conversion: Bool = false) -> String {
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
            status += "\(prescriptionCount.removeTrailingZero()) \(dosageUnit.units(prescriptionCount)) of \(name!). "
            
            if let days = refillDaysRemaining(), !entry {
                if days <= 1 {
                    status += "You will need to refill after this dose. "
                } else {
                    status += "Based on your current usage, this will last you approximately \(days) \(Intervals.daily.units(Float(days))). "
                }
            }
        }
        
        return status
    }
    
    
    // MARK: - Notification methods
    var doseNotificationIdentifier: String {
        return "\(medicineID)-dose"
    }
    
    func scheduleNotification(_ date: Date, badgeCount: Int = 1) throws {
        // Schedule if the user wants a reminder and the reminder date is in the future
        guard date.compare(Date()) == .orderedDescending else {
            throw MedicineError.datePassed
        }
        
        guard reminderEnabled == true else {
            print(self.doseNotificationIdentifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.doseNotificationIdentifier])
            throw MedicineError.reminderDisabled
        }
        
        guard let name = name else {
            throw MedicineError.invalidName
        }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let content = UNMutableNotificationContent()
        content.title = "Take \(name)"
        content.body = String(format:"Time to take %g %@ of %@", dosage, dosageUnit.units(dosage), name)
        content.sound = UNNotificationSound.default()
        content.badge = NSNumber(integerLiteral: badgeCount)
        content.userInfo = ["id": medicineID]
        
        if lastDose == nil && intervalUnit == .daily {
            content.categoryIdentifier = "Dose Reminder - No Snooze"
        } else {
            content.categoryIdentifier = "Dose Reminder"
        }

        let request = UNNotificationRequest(identifier: doseNotificationIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
            if error == nil {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .medium
                print("DOSE Notification scheduled for \(formatter.string(from: date)) for \"\(name)\".")
            } else {
                print("Error scheduling DOSE notification for \(name).")
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.doseNotificationIdentifier])
            }
        }
    }
    
    @discardableResult func scheduleNextNotification() -> Bool {
        guard let date = nextDose else {
            return false
        }
        
        do {
            try scheduleNotification(date, badgeCount: Medicine.overdueCount(date))
            NSLog("\tScheduled notification for: \(self.name!)")
            return true
        } catch {
            return false
        }
    }
    
    @discardableResult func snoozeNotification() -> Bool {
        let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine")!
        var snoozeDate = Date()
        
        // Set snooze delay to user selection or 5 minutes
        if defaults.value(forKey: "snoozeLength") != nil {
            let val = defaults.value(forKey: "snoozeLength") as! Int
            snoozeDate = (cal as NSCalendar).date(byAdding: NSCalendar.Unit.minute, value: val, to: Date(), options: [])!
        } else {
            snoozeDate = (cal as NSCalendar).date(byAdding: NSCalendar.Unit.minute, value: 5, to: Date(), options: [])!
        }
        
        // Update last dose next value in case notifications are rescheduled
        self.lastDose?.next = snoozeDate
        
        // Save modifications to last dose
        let cdStack = (UIApplication.shared.delegate as! AppDelegate).stack
        cdStack.save()
        
        // Schedule new notification
        do {
            try scheduleNotification(snoozeDate)
            return true
        } catch {
            return false
        }
    }
    
    var refillNotificationIdentifier: String {
        return "\(medicineID)-refill"
    }
    
    func sendRefillNotification() {
        if refillFlag {
            let now = Date()
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: now)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let content = UNMutableNotificationContent()
            content.title = "Refill \(name!)"
            
            var message = "You are running low on \(name!) and should refill soon."
            if prescriptionCount < dosage {
                message = "You don't have enough \(name!) to take your next dose."
            } else if let count = refillDaysRemaining(), prescriptionCount > 0 && count > 0 {
                message = "You currently have enough \(name!) for about \(count) \(count == 1 ? "day" : "days") and should refill soon."
            }
            content.body = message
            
            content.sound = UNNotificationSound.default()
            content.userInfo = ["id": self.medicineID, "type": "refill"]
            content.categoryIdentifier = "Refill Reminder"
            
            let request = UNNotificationRequest(identifier: refillNotificationIdentifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { (error) in
                if error == nil {
                    print("REFILL notification scheduled for \(now) for \"\(self.name!)\".")
                    self.refillFlag = false
                } else {
                    print("Error scheduling REFILL notification for \(self.name!).")
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.refillNotificationIdentifier])
                }
            }
        }
    }
    
    
    // MARK: - Helper method
    
    /**
    Determine the number of overdue items at a specific date
    
    - Parameter date: Date at which to determine overdue count
    
    - Returns: Number of overdue items at date
    */
    class func overdueCount(_ date: Date = Date()) -> Int {
        let cdStack = (UIApplication.shared.delegate as! AppDelegate).stack
        let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
        request.predicate = NSPredicate(format: "reminderEnabled == true", argumentArray: [])
        if let medication = try? cdStack.context.fetch(request) {
            return medication.filter({
                guard let next = $0.nextDose else { return false }
                return next.compare(date) != .orderedDescending
            }).count
        } else {
            return 0
        }
    }
    
    /**
    Determine the date of the next dose from the current time or optional parameter
    
    - Parameter date: Optional date from which to calculate
    
    - Returns: Date of next dose or nil
    
    - Throws: 'MedicineError.NoAlarm' if medication has daily interval and no alarm set
    */
    func calculateNextDose(_ date: Date? = nil) throws -> Date? {
        switch(intervalUnit) {
        case .none:
            return nil
        case .hourly:
            let hr = Int(interval)
            let min = Int(60 * (interval.truncatingRemainder(dividingBy: 1)))
            
            // Calculate interval from date provided
            if let date = date {
                var next = (cal as NSCalendar).date(byAdding: NSCalendar.Unit.hour, value: hr, to: date, options: [])!
                next = (cal as NSCalendar).date(byAdding: NSCalendar.Unit.minute, value: min, to: next, options: [])!
                return next
            }
            
            // Calculate interval based on last dose
            return lastDose?.next as Date?
            
        case .daily:
            guard let alarm = intervalAlarm else {
                throw MedicineError.noAlarm
            }
            
            // Calculate interval from date provided
            if let date = date {
                let components = (cal as NSCalendar).components([NSCalendar.Unit.hour, NSCalendar.Unit.minute], from: alarm as Date)
                let date = (cal as NSCalendar).date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: date, options: [])!
                return (cal as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: Int(interval), to: date, options: [])
            }
            
            // Return pre-calculated next dose and handle snooze
            if lastDose?.next?.compare(Date()) == .orderedDescending {
                return lastDose?.next as Date?
            }
            
            var date = Date()
            let components = (cal as NSCalendar).components([NSCalendar.Unit.hour, NSCalendar.Unit.minute], from: alarm as Date)
            
            if lastDose?.date == nil {
                date = alarm as Date
            } else if let last = lastDose?.date {
                date = (cal as NSCalendar).date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: last as Date, options: [])!
            }
            
            // If medicine was created today but the alarm is behind the current time, set for tomorrow
            if let dateCreated = dateCreated, cal.isDateInToday(dateCreated as Date) {
                while date.compare(Date()) == .orderedAscending {
                    date = (cal as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: 1, to: date, options: [])!
                }
            }
            
            // If dose is scheduled for today but in the past, mark as overdue
            if cal.isDateInToday(date) {
                return date
            } else {
                // Schedule for next interval until it is for the future
                while date.compare(Date()) == .orderedAscending && cal.isDateInToday(date) == false {
                    date = (cal as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: Int(interval), to: date, options: [])!
                }
            }
            
            if lastDose?.next?.compare(Date()) == .orderedAscending {
                lastDose?.next = date
            }
            
            return date
        default: break
        }
        
        return nil
    }
    
}


// MARK: - NSDate extension
extension Date {

    // Determines if time is set to midnight
    func isMidnight() -> Bool {
        let cal = Calendar.current
        let currentDate = Date()
        let components = (cal as NSCalendar).components([NSCalendar.Unit.hour, NSCalendar.Unit.minute], from: self)
        
        if let compare = (cal as NSCalendar).date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: currentDate, options: []) {
            if ((cal as NSCalendar).isDate(compare, equalTo: cal.startOfDay(for: currentDate), toUnitGranularity: NSCalendar.Unit.minute)) {
                return true
            }
        }
        
        return false
    }
    
    func isDateInLastWeek() -> Bool {
        let cal = Calendar.current
        let currentDate = Date()
        var val = false
        
        if self.compare((cal as NSCalendar).date(byAdding: NSCalendar.Unit.weekOfYear, value: -1, to: cal.startOfDay(for: currentDate), options: [])!) == .orderedDescending {
            if self.compare(currentDate) == .orderedAscending {
                val = true
            }
        }
        
        return val
    }
    
    func isDateInWeek() -> Bool {
        let cal = Calendar.current
        let currentDate = Date()
        var val = false
        
        if self.compare((cal as NSCalendar).date(byAdding: NSCalendar.Unit.weekOfYear, value: 1, to: cal.startOfDay(for: currentDate), options: [])!) == .orderedAscending {
            if self.compare((cal as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: -1, to: cal.startOfDay(for: currentDate), options: [])!) == .orderedDescending {
                val = true
            }
        }

        return val
    }
    
}


// MARK: - Array extension
extension Array {
    mutating func removeObject<U: Equatable>(_ object: U) {
        for (index, compare) in self.enumerated() {
            if let compare = compare as? U {
                if object == compare {
                    self.remove(at: index)
                    break
                }
            }
        }
    }
}


// MARK: - Float extension
extension Float {
    /**
     Removes trailing zeroes from passed number
     
     Parameter num: Float value to truncate
     
     Returns: Number as a string with trailing zeroes truncated
     */
    func removeTrailingZero() -> String {
        return String(format: "%g", self)
    }
}


// MARK: - Errors Enum
enum MedicineError: Error {
    case invalidName
    case tooSoon
    case datePassed
    case reminderDisabled
    case noAlarm
}


// MARK: - Sort Order Enum
enum SortOrder: Int {
    case manual
    case nextDosage
}


// MARK: - Units Enum
enum Doses: Int16, CustomStringConvertible {
    case pills
    case milligrams
    case millilitres
    case puffs
    
    static var count: Int {
        return 4
    }
    
    var description: String {
        switch self {
        case .pills: return "Pills"
        case .milligrams: return "Milligrams"
        case .millilitres: return "Millilitres"
        case .puffs: return "Puffs"
        }
    }
    
    func units(_ amount: Float?) -> String {
        switch self {
        case .pills:
            if (amount != nil && amount == 1.0) {
                return "pill"
            } else {
                return "pills"
            }
        case .milligrams: return "mg"
        case .millilitres: return "mL"
        case .puffs:
            if (amount != nil && amount == 1.0) {
                return "puff"
            } else {
                return "puffs"
            }
        }
    }
}


// MARK: - Frequencies Enum
enum Intervals: Int16, CustomStringConvertible {
    case none = -1
    case hourly = 0
    case daily
    case weekly
    
    static var count: Int {
        return 2
    }
    
    var description: String {
        switch self {
        case .hourly: return "Hourly"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        default: return "None"
        }
    }
    
    func units(_ amount: Float?) -> String {
        var string = ""
        
        switch self {
        case .hourly: string = "hour"
        case .daily: string = "day"
        case .weekly: string = "week"
        default: string = "none"
        }
        
        if let amt = amount {
            if (amt < 1 || amt >= 2) {
                string += "s"
            }
        }
        
        return string
    }
    
}
