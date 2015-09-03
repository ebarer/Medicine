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

    @NSManaged var conversion: Int16
    @NSManaged var date: NSTimeInterval
    @NSManaged var quantity: Int16
    @NSManaged var medicine: Medicine?

}
