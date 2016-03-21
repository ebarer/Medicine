//
//  Medicine+CoreDataProperties.swift
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

extension Medicine {

    @NSManaged var dateCreated: NSDate?
    
    @NSManaged var name: String?
    @NSManaged var medicineID: String
    @NSManaged var sortOrder: Int16
    
    @NSManaged var dosage: Float
    @NSManaged var dosageUnitInt: Int16

    @NSManaged var reminderEnabled: Bool
    @NSManaged var interval: Float
    @NSManaged var intervalUnitInt: Int16
    @NSManaged var intervalAlarm: NSDate?
    
    @NSManaged var doseHistory: NSOrderedSet?
    
    @NSManaged var prescriptionCount: Float
    @NSManaged var refillHistory: NSOrderedSet?
    @NSManaged var refillFlag: Bool
    
    @NSManaged var notes: String?
    
}