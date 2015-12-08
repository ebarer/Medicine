//
//  MedicineCell+Adherence.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-11-01.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class MedicineCell_Adherence: UIView {
    
    var score: Int?
    var scoreLabel: UILabel = UILabel()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.backgroundColor = UIColor.whiteColor()
        
        if let score = score {
            scoreLabel.frame = CGRectMake(0, 0, 50, 50)
            scoreLabel.backgroundColor = UIColor.redColor()
            scoreLabel.textAlignment = NSTextAlignment.Center
            scoreLabel.text = "\(score)"
            self.addSubview(scoreLabel)
        }
    }
    
}
