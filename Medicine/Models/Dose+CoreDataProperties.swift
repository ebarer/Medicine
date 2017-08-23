//
//  Dose+CoreDataProperties.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-28.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Dose {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Dose> {
        return NSFetchRequest<Dose>(entityName: "Dose")
    }
    
    @NSManaged var medicine: Medicine?
    
    @NSManaged var date: Date
    
    @objc public var dateSection: Date? {
        return Calendar.current.startOfDay(for: date)
    }
    
    @NSManaged var expectedDate: Date?
    @NSManaged var next: Date?
    
    @NSManaged var dosage: Float
    @NSManaged var dosageUnitInt: Int16

}
