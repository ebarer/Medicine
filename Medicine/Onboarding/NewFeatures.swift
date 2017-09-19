//
//  NewFeatures.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-11-10.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class NewFeatures: UIViewController {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
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
        self.dismiss(animated: true)
    }
}
