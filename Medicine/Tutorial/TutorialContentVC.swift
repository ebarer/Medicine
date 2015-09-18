//
//  TutorialContentVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-16.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class TutorialContentVC: UIViewController {
    
    var index: Int = 0
    var tutorialTitle: String?
    
    
    // MARK: - Outlets
    @IBOutlet var tutorialCopy: UILabel!
    
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tutorialCopy.text = tutorialTitle
    }
}
