//
//  MedicineCell.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-11-01.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class MedicineCell: UITableViewCell {
    
    // MARK: - Cell properties
    @IBOutlet var adherenceScore: UIView!
    @IBOutlet var title: UILabel!
    @IBOutlet var subtitle: UILabel!
    @IBOutlet var subtitleGlyph: UIImageView!
    var glyphHidden = false
    
    // MARK: - Constraints
    @IBOutlet var adherenceWidth: NSLayoutConstraint!
    @IBOutlet var titleLeading: NSLayoutConstraint!
    @IBOutlet var glyphWidth: NSLayoutConstraint!
    @IBOutlet var subtitleLeading: NSLayoutConstraint!
    
    
    // MARK: - General
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set tint
        self.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        if editing {
            adherenceWidth.constant = 0.0
            titleLeading.constant = 0.0
            subtitleLeading.constant = glyphHidden ? -5.0 : 0.0
        } else {
            // Width to display adherence score
            //adherenceWidth.constant = 50.0
            
            adherenceWidth.constant = 0.0
            titleLeading.constant = 10.0
            subtitleLeading.constant = glyphHidden ? 5.0 : 10.0
        }
        
        self.setNeedsUpdateConstraints()
        UIView.animateWithDuration(NSTimeInterval(0.25)) { () -> Void in
            self.layoutIfNeeded()
            super.setEditing(editing, animated: animated)
        }
    }
    
    func hideGlyph(val: Bool) {
        if val {
            glyphHidden = true
            glyphWidth.constant = 0.0
            subtitleLeading.constant = 5.0
        } else {
            glyphHidden = false
            glyphWidth.constant = 20.0
            subtitleLeading.constant = 10.0
        }
        
        self.setNeedsUpdateConstraints()
        self.layoutIfNeeded()
    }

}
