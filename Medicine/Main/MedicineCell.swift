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
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet var stackTrailing: NSLayoutConstraint!
    var rowEditing: Bool = false
    
    // MARK: - View methods
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectedBackgroundView = UIView()
        
        self.clipsToBounds = true
        self.tintColor = UIColor.medRed
        self.backgroundColor = .clear
        
        self.cellFrame?.layer.backgroundColor = UIColor.cellBackground.cgColor
        self.cellFrame?.layer.cornerRadius = 10.0
        
        // Setup fonts
        title.font = UIFont.preferredFont(for: .title2, weight: .medium)
    }
    
    override func prepareForReuse() {
        subtitleGlyph.image = UIImage(named: "NextDoseIcon")
        subtitle.textColor = UIColor.subtitleLabel
        enableChevron(enable: false)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if !rowEditing {
            if selected {
                self.cellFrame?.layer.backgroundColor = UIColor.cellBackgroundSelected.cgColor
                self.cellShadow?.layer.backgroundColor = UIColor.cellBackground.cgColor
            } else {
                self.cellFrame?.layer.backgroundColor = UIColor.cellBackground.cgColor
                self.cellShadow?.layer.backgroundColor = UIColor.cellBackground.cgColor
            }
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if !rowEditing {
            if highlighted {
                self.cellFrame?.layer.backgroundColor = UIColor.cellBackgroundSelected.cgColor
                self.cellShadow?.layer.backgroundColor = UIColor.cellBackground.cgColor
            } else {
                self.cellFrame?.layer.backgroundColor = UIColor.cellBackground.cgColor
                self.cellShadow?.layer.backgroundColor = UIColor.cellBackground.cgColor
            }
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        var shouldEnableChevron = med?.doseHistory?.count == 0 && med?.intervalUnit == .hourly
        shouldEnableChevron = shouldEnableChevron || (editing && !rowEditing)
        enableChevron(enable: shouldEnableChevron)
    }
    
    func enableChevron(enable: Bool) {
        if #available(iOS 13.0, *) {
            if enable {
                self.actionButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
                self.actionButton.isEnabled = false
                self.stackTrailing.constant = 15.0
            } else {
                self.actionButton.setImage(UIImage(named: "ActionIcon"), for: .normal)
                self.actionButton.isEnabled = true
                self.stackTrailing.constant = 25.0
            }
        } else {
            self.hideButton(enable, animated: true)
        }
    }
    
    func hideButton(_ hide: Bool, animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.actionButton.alpha = hide ? 0 : 1
            }, completion: { (completed) in
                self.actionButton.isHidden = hide
            })
        } else {
            self.actionButton.alpha = hide ? 0 : 1
            self.actionButton.isHidden = hide
        }
    }

}
