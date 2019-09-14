//
//  Dose.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-08-28.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class Dose: NSManagedObject {

    convenience init(insertInto context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Dose", in: context) {
            self.init(entity: entity, insertInto: context)
        } else {
            let message = "Unable to find Dose entity."
            NSLog("CoreData", message)
            fatalError(message)
        }
    }
    
    var dosageUnit: Doses {
        get { return Doses(rawValue: self.dosageUnitInt)! }
        set { self.dosageUnitInt = newValue.rawValue }
    }
    
}
