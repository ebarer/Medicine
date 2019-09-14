//
//  MedicineCell+CellFrame.swift
//  Medicine
//
//  Created by Elliot Barer on 2017-09-02.
//  Copyright © 2017 Elliot Barer. All rights reserved.
//

import UIKit

class MedicineCell_CellFrame: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        drawShadow()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.backgroundColor = UIColor.cellBackground.cgColor
        self.layer.cornerRadius = 10.0
        drawShadow()
    }
    
    func drawShadow() {
        self.layer.shadowOffset = CGSize(width: 0, height: 3)
        self.layer.shadowRadius = 3
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.3
    }
}
