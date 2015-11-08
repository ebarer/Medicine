//
//  Prescription.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-03.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData

class Prescription: NSManagedObject {
    
    var quantityUnit: Doses {
        get { return Doses(rawValue: self.quantityUnitInt)! }
        set { self.quantityUnitInt = newValue.rawValue }
    }

}
