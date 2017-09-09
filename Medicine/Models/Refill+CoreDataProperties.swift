//
//  Refill+CoreDataProperties.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-03.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Refill {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Refill> {
        return NSFetchRequest<Refill>(entityName: "Refill")
    }
    
    @NSManaged var medicine: Medicine?
    
    @NSManaged var date: Date
    
    @objc public var dateSection: Date? {
        return Calendar.current.startOfDay(for: date)
    }
    
    @NSManaged var quantity: Float
    @NSManaged var quantityUnitInt: Int16
    @NSManaged var conversion: Float

}
