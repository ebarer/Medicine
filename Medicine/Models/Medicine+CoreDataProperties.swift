//
//  Medicine+CoreDataProperties.swift
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

extension Medicine {
    
    @NSManaged var medicineID: String
    @NSManaged var name: String?
    
    @NSManaged var dosageAmount: Float
    @NSManaged var dosageType: Int16
    
    @NSManaged var frequencyDuration: Float
    @NSManaged var frequencyInterval: Int16
    @NSManaged var timeEnd: NSTimeInterval
    @NSManaged var timeStart: NSTimeInterval

    @NSManaged var dosageNext: NSTimeInterval
    @NSManaged var history: NSOrderedSet?

}
