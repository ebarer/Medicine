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
    @IBOutlet var dateLabel: UILabel?
    @IBOutlet var medLabel: UILabel?
    @IBOutlet var historyLabel: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCell()
    }
    
    override func prepareForReuse() {
        setupCell()
    }
    
    func setupCell() {
        dateLabel?.isHidden = false
        dateLabel?.text = nil
        dateLabel?.textColor = UIColor(white: 0.22, alpha: 1)
        
        medLabel?.text = nil
        medLabel?.textColor = UIColor(white: 0.22, alpha: 1)

        historyLabel?.isHidden = false
        historyLabel?.text = nil
        historyLabel?.textColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
