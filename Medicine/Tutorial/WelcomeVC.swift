//
//  WelcomeVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-11-10.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class WelcomeVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func dismiss() {
        NSNotificationCenter.defaultCenter().postNotificationName("refreshMedication", object: nil, userInfo: nil)
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
