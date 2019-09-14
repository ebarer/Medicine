//
//  FirstLaunch.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-11-10.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class FirstLaunch: UIViewController {

    // MARK:- Outlets
    @IBOutlet var appIcon: UIImageView!
    @IBOutlet var welcomeMessage: UILabel!
    @IBOutlet var advanceButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, macCatalyst 13.0, *) {
            self.navigationController?.isModalInPresentation = true
        }
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        appIcon.layer.masksToBounds = true
        appIcon.layer.cornerRadius = 15.0
        
        advanceButton.layer.cornerRadius = 10.0
        
        let message: NSString = "Welcome to Medicine Manager"
        let attString = NSMutableAttributedString(string: message as String)
        
        var range = message.range(of: "Medicine Manager")
        attString.addAttribute(.foregroundColor, value: UIColor.medRed, range: range)
        
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 0.8
        range = NSRange(location: 0, length: message.length)
        attString.addAttribute(.paragraphStyle, value: style, range: range)
        
        welcomeMessage.attributedText = attString
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
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
}
