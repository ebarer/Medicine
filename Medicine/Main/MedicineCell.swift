//
//  MedicineCell.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-11-01.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class MedicineCell: UITableViewCell {
    
    var med: Medicine?
    
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
        self.tintColor = UIColor.medRed
        self.backgroundColor = .clear
        
        self.cellFrame?.layer.backgroundColor = UIColor.white.cgColor
        self.cellFrame?.layer.cornerRadius = 10.0
    }
    
    override func prepareForReuse() {
        subtitleGlyph.image = UIImage(named: "NextDoseIcon")
        subtitle.textColor = UIColor.subtitle
        hideButton(false, animated: false)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if !rowEditing {
            if selected {
                self.cellFrame?.layer.backgroundColor = UIColor(white: 0.84, alpha: 1).cgColor
                self.cellShadow?.layer.backgroundColor = UIColor.white.cgColor
            } else {
                self.cellFrame?.layer.backgroundColor = UIColor.white.cgColor
                self.cellShadow?.layer.backgroundColor = UIColor.white.cgColor
            }
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if !rowEditing {
            if highlighted {
                self.cellFrame?.layer.backgroundColor = UIColor(white: 0.84, alpha: 1).cgColor
                self.cellShadow?.layer.backgroundColor = UIColor.white.cgColor
            } else {
                self.cellFrame?.layer.backgroundColor = UIColor.white.cgColor
                self.cellShadow?.layer.backgroundColor = UIColor.white.cgColor
            }
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if med?.doseHistory?.count == 0 && med?.intervalUnit == .hourly {
            self.hideButton(true, animated: false)
            return
        }
        
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
            }, completion: { (completed) in
                self.addButton.isHidden = hide
            })
        } else {
            self.addButton.alpha = hide ? 0 : 1
            self.addButton.isHidden = hide
        }
    }

}
