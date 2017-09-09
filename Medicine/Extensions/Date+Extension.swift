//
//  Date+Extension.swift
//  Medicine
//
//  Created by Elliot Barer on 2017-09-03.
//  Copyright © 2017 Elliot Barer. All rights reserved.
//

import UIKit

extension Date {
    
    func string(dateStyle: DateFormatter.Style = .none, timeStyle: DateFormatter.Style = .none) -> String? {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }
    
    func string(withFormat format: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    static func fromString(_ dateString: String, withFormat format: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: dateString)
    }

}
