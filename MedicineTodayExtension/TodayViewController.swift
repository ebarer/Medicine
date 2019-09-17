//
//  TodayViewController.swift
//  MedicineTodayExtension
//
//  Created by Elliot Barer on 2015-10-01.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    @IBOutlet var doseMainLabel: UILabel!
    @IBOutlet var doseMedLabel: UILabel!
    let cal = Calendar.current
    
// MARK: - Action
    @IBAction func tapWidget(_ sender: Any) {
        if let url = URL(string: "medicine://") {
            self.extensionContext?.open(url, completionHandler: nil)
        }
    }
    
// MARK: - Update
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        let updateResult = updateLabels()
        if updateResult == .noData {
            NCWidgetController().setHasContent(false, forWidgetWithBundleIdentifier: "com.ebarer.Medicine.MedicineTodayExtension")
        }
        completionHandler(updateResult)
    }
    
    func updateLabels() -> NCUpdateResult {
        guard let med = getMostRecentMedication() else {
            return NCUpdateResult.noData
        }
        
        guard let date = med.nextDose else {
            return updateForNoMoreDoses()
        }
        
        switch (date) {
        case let date where date < Date():
            return updateForOverdueDose(med: med)
        case let date where Calendar.current.isDateInToday(date):
            return updateForUpcomingDose(med: med, date: date)
        default:
            return updateForNoMoreDoses()
        }

    }
    
    func updateForOverdueDose(med: Medicine) -> NCUpdateResult {
        let doseMainLabelText = NSMutableAttributedString(string: " Overdue")
        doseMainLabelText.addAttribute(NSAttributedString.Key.font,
                                       value: UIFont.systemFont(ofSize: 36.0),
                                       range: NSMakeRange(0, doseMainLabelText.length))
        
        doseMainLabel.attributedText = doseMainLabelText
        
        let warningIconAttachment = NSTextAttachment()
        warningIconAttachment.image = UIImage(named: "OverdueIcon")
        let size = doseMainLabel.font.capHeight
        warningIconAttachment.bounds = CGRect(x: 0, y: 0, width: size, height: size)
        let warningIconString = NSAttributedString(attachment: warningIconAttachment)
        
        doseMainLabelText.insert(warningIconString, at: 0)
        
        doseMainLabelText.addAttribute(NSAttributedString.Key.foregroundColor,
                                       value: UIColor.medRedWidget,
                                       range: NSMakeRange(0, doseMainLabelText.length))
        
        doseMainLabel.attributedText = doseMainLabelText
        updateMedLabel(med)
        
        return NCUpdateResult.newData
    }
    
    func updateForUpcomingDose(med: Medicine, date: Date) -> NCUpdateResult {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let dateString = formatter.string(from: date)
        let doseMainLabelText = NSMutableAttributedString(string: dateString)
        var color: UIColor
        if #available(iOS 13.0, macCatalyst 13.0, *) {
            color = UIColor.label
        } else {
            color = UIColor.black
        }
        doseMainLabelText.addAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 48.0, weight: UIFont.Weight.light),
                                         NSAttributedString.Key.foregroundColor : color],
                                        range: NSMakeRange(0, doseMainLabelText.length))
        
        // Accomodate 24h times
        if let range = (dateString.contains("AM")) ? dateString.range(of: "AM") : dateString.range(of: "PM") {
            let pos = dateString.distance(from: dateString.startIndex, to: range.lowerBound)
            doseMainLabelText.addAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 24.0),
                                             NSAttributedString.Key.foregroundColor : UIColor.medGray1],
                                            range: NSMakeRange(pos - 1, 3))
        }
        
        doseMainLabel.attributedText = doseMainLabelText
        updateMedLabel(med)
        
        return NCUpdateResult.newData
    }
    
    func updateForNoMoreDoses() -> NCUpdateResult {
        let doseMainLabelText = NSMutableAttributedString(string: "No scheduled doses today")
        
        var color: UIColor
        if #available(iOS 13.0, macCatalyst 13.0, *) {
            color = UIColor.label
        } else {
            color = UIColor.black
        }
        
        doseMainLabelText.addAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 24.0, weight: UIFont.Weight.light),
                                         NSAttributedString.Key.foregroundColor : color],
                                        range: NSMakeRange(0, doseMainLabelText.length))

        doseMedLabel.isHidden = true
        
        return NCUpdateResult.newData
    }
    
    func updateMedLabel(_ med: Medicine) {
        let dose = String(format:"%g %@", med.dosage, med.dosageUnit.units(med.dosage))
        let doseMedLabelText = "\(dose) of \(med.name!)"

        doseMedLabel.text = doseMedLabelText
        
        if #available(iOS 13.0, macCatalyst 13.0, *) {
            doseMedLabel.textColor = UIColor.label
        } else {
            doseMedLabel.textColor = UIColor.black
        }
        
        doseMedLabel.isHidden = false
    }
    
// MARK: - Helper
    func getMostRecentMedication() -> Medicine? {
        let fetchRequest: NSFetchRequest<Medicine> = Medicine.fetchRequest()
        fetchRequest.includesPendingChanges = true
        fetchRequest.shouldRefreshRefetchedObjects = true
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "isNew", ascending: false),
            NSSortDescriptor(key: "reminderEnabled", ascending: false),
            NSSortDescriptor(key: "hasNextDose", ascending: false),
            NSSortDescriptor(key: "dateNextDose", ascending: true),
            NSSortDescriptor(key: "dateLastDose", ascending: false)
        ]
        
        CoreDataStack.shared.persistingContext.refreshAllObjects()
        
        let medication = try? CoreDataStack.shared.persistingContext.fetch(fetchRequest)
        return medication?.sorted(by: Medicine.sortByNextDose).filter({ $0.reminderEnabled }).first
    }
}
