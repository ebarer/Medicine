//
//  Prescription+CoreDataProperties.swift
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

extension Prescription {

    @NSManaged var date: NSDate
    @NSManaged var medicine: Medicine?
    
    @NSManaged var quantity: Float
    @NSManaged var conversion: Float

}
