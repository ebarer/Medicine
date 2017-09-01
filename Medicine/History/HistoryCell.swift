//
//  HistoryCell.swift
//  Medicine
//
//  Created by Elliot Barer on 2017-09-01.
//  Copyright © 2017 Elliot Barer. All rights reserved.
//

import UIKit

class HistoryCell: UITableViewCell {

    // MARK: - Outlets
    
    @IBOutlet var medLabel: UILabel?
    @IBOutlet var historyLabel: UILabel?
    @IBOutlet var dateLabel: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCell()
    }
    
    override func prepareForReuse() {
        setupCell()
    }
    
    func setupCell() {
        medLabel?.text = nil
        medLabel?.textColor = UIColor.darkGray

        historyLabel?.isHidden = false
        historyLabel?.text = nil
        historyLabel?.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        
        dateLabel?.isHidden = false
        dateLabel?.text = nil
        dateLabel?.textColor = UIColor.darkGray
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
