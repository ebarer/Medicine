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
    @IBOutlet var title: UILabel!
    @IBOutlet var subtitle: UILabel!
    @IBOutlet var subtitleGlyph: UIImageView!
    
    var longPressGesture: UILongPressGestureRecognizer? {
        didSet {
            self.addGestureRecognizer(longPressGesture!)
        }
    }
    
    // MARK: - Constraints
    @IBOutlet var glyphWidth: NSLayoutConstraint!
    @IBOutlet weak var addButton: UIButton!
    var rowEditing: Bool = false
    
    override var alpha: CGFloat {
        didSet {
            super.alpha = 1
        }
    }
    
    // MARK: - View methods
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.clipsToBounds = true
        self.tintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        self.backgroundColor = .clear
        self.selectedBackgroundView = UIView()
        
        cellFrame?.layer.backgroundColor = UIColor.white.cgColor
        cellFrame?.layer.cornerRadius = 10.0
        drawShadow()
    }
    
    override func prepareForReuse() {
        addButton.isHidden = false
        addButton.alpha = 1.0
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            self.cellFrame?.layer.backgroundColor = UIColor(white: 0.9, alpha: 1).cgColor
        } else {
            self.cellFrame?.layer.backgroundColor = UIColor.white.cgColor
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted {
            self.cellFrame?.layer.backgroundColor = UIColor(white: 0.9, alpha: 1).cgColor
        } else {
            self.cellFrame?.layer.backgroundColor = UIColor.white.cgColor
        }
    }
    
    // Remove long press gesture when editing to prevent issues with reordering
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if let gesture = longPressGesture {
            if editing {
                if !rowEditing {
                    self.hideButton(true)
                }
                self.removeGestureRecognizer(gesture)
            } else {
                self.hideButton(false)
                self.addGestureRecognizer(gesture)
            }
        }
    }
    
    override var frame: CGRect {
        didSet {
            cellFrame?.layer.backgroundColor = UIColor.white.cgColor
        }
    }
    
    func drawShadow() {
        cellFrame?.layer.shadowOffset = CGSize(width: 0, height: 1)
        cellFrame?.layer.shadowRadius = 2
        cellFrame?.layer.shadowColor = UIColor.black.cgColor
        cellFrame?.layer.shadowOpacity = 0.15
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
