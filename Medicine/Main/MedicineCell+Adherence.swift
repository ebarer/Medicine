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
        
        self.backgroundColor = UIColor.white
        
        if let score = score {
            scoreLabel.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            scoreLabel.backgroundColor = UIColor.red
            scoreLabel.textAlignment = NSTextAlignment.center
            scoreLabel.text = "\(score)"
            self.addSubview(scoreLabel)
        }
    }
    
}
