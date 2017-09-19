//
//  FirstLaunch+Notifications.swift
//  Medicine
//
//  Created by Elliot Barer on 2017-09-19.
//  Copyright © 2017 Elliot Barer. All rights reserved.
//

import UIKit
import UserNotifications

class FirstLaunch_Notifications: UIViewController {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    // MARK:- Outlets
    @IBOutlet var allowButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        allowButton.layer.cornerRadius = 10
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
    
    
    @IBAction func authorizeNotifications(_ sender: Any) {
        print("Notification authorization: Authorized")
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {(accepted, error) in
                    if accepted {
                        self.appDelegate.configureNotificationAuthorization()
                        self.dismiss(animated: true)
                    } else {
                        NSLog("Notification access denied.", [])
                        self.dismiss(animated: true)
                    }
                }
            } else {
                self.dismiss(animated: true)
            }
        }
    }
    
    @IBAction func denyNotifications(_ sender: Any) {
        NSLog("Notification authorization: Denied")
        self.dismiss(animated: true)
    }

}

