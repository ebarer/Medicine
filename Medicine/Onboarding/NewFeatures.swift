//
//  NewFeatures.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-11-10.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class NewFeatures: UIViewController {

    // MARK: - Helper variables
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine")!
    
    // MARK:- Outlets
    @IBOutlet var dismissButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dismissButton.layer.cornerRadius = 10.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Button events
    @IBAction func touchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2) {
            sender.layer.backgroundColor = sender.layer.backgroundColor?.copy(alpha: 0.5)
        }
    }
    
    @IBAction func touchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2) {
            sender.layer.backgroundColor = sender.layer.backgroundColor?.copy(alpha: 1.0)
        }
    }

    @IBAction func dismiss(_ sender: AnyObject) {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleVersion"] as! String
        
        defaults.set(true, forKey: "finishedFirstLaunch")
        defaults.setValue(version, forKey: "version")
        defaults.synchronize()

        self.dismiss(animated: true)
    }
}
