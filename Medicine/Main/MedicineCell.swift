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
    
    @IBOutlet var adherenceScore: MedicineCell_Adherence!
    @IBOutlet var adherenceScoreLabel: UILabel!
    @IBOutlet var title: UILabel!
    @IBOutlet var subtitle: UILabel!
    @IBOutlet var subtitleGlyph: UIImageView!
    var glyphHidden = false
    var buttonHidden = false

    
    // MARK: - Constraints
    
    @IBOutlet var adherenceWidth: NSLayoutConstraint!
    @IBOutlet var titleLeading: NSLayoutConstraint!
    @IBOutlet var glyphWidth: NSLayoutConstraint!
    @IBOutlet weak var glyphLeading: NSLayoutConstraint!
    @IBOutlet var subtitleLeading: NSLayoutConstraint!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var addButtonTrailing: NSLayoutConstraint!
    
    // MARK: - View methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set tint
        self.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        
        // Hide adherence field
        adherenceWidth.constant = 0.0
        titleLeading.constant = 0.0
        glyphLeading.constant = 0.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func hideGlyph(_ val: Bool) {
        if val {
            glyphHidden = true
            glyphWidth.constant = 0.0
            subtitleLeading.constant = 0.0
        } else {
            glyphHidden = false
            glyphWidth.constant = 20.0
            subtitleLeading.constant = 8.0
        }
        
        self.setNeedsUpdateConstraints()
        self.layoutIfNeeded()
    }
    
    func hideButton(_ val: Bool) {
        addButton.isHidden = val
        buttonHidden = val
    }

}
