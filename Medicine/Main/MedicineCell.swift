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
    @IBOutlet var cellFrame: UIView?
    @IBOutlet var cellShadow: MedicineCell_CellFrame?
    @IBOutlet var title: UILabel!
    @IBOutlet var subtitle: UILabel!
    @IBOutlet var subtitleGlyph: UIImageView!
    
    override var frame: CGRect {
        didSet {
            self.setSelected(self.isSelected, animated: false)
        }
    }
    
    // MARK: - Constraints
    @IBOutlet var glyphWidth: NSLayoutConstraint!
    @IBOutlet weak var addButton: UIButton!
    var rowEditing: Bool = false
    
    // MARK: - View methods
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectedBackgroundView = UIView()
        
        self.clipsToBounds = true
        self.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        self.backgroundColor = .clear
        
        self.cellFrame?.layer.backgroundColor = UIColor.white.cgColor
        self.cellFrame?.layer.cornerRadius = 10.0
    }
    
    override func prepareForReuse() {
        addButton.isHidden = false
        addButton.alpha = 1.0
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            self.cellFrame?.layer.backgroundColor = UIColor(white: 0.95, alpha: 1).cgColor
            self.cellShadow?.layer.backgroundColor = UIColor.white.cgColor
        } else {
            self.cellFrame?.layer.backgroundColor = UIColor.white.cgColor
            self.cellShadow?.layer.backgroundColor = UIColor.white.cgColor
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted {
            self.cellFrame?.layer.backgroundColor = UIColor(white: 0.95, alpha: 1).cgColor
            self.cellShadow?.layer.backgroundColor = UIColor.white.cgColor
        } else {
            self.cellFrame?.layer.backgroundColor = UIColor.white.cgColor
            self.cellShadow?.layer.backgroundColor = UIColor.white.cgColor
        }
    }
    
    // Remove long press gesture when editing to prevent issues with reordering
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing && !rowEditing {
            self.hideButton(true)
        } else {
            self.hideButton(false)
        }
    }
    
    func hideButton(_ hide: Bool, animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.addButton.alpha = hide ? 0 : 1
            })
        } else {
            self.addButton.isHidden = hide
        }
    }

}
