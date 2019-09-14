//
//  TodayViewController.swift
//  MedicineTodayExtension
//
//  Created by Elliot Barer on 2015-10-01.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {

    let cal = Calendar.current
    let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine")!
    
    
    // MARK: - Outlets
    @IBOutlet var topConstraint: NSLayoutConstraint!
    @IBOutlet var doseMainLabel: UILabel!
    @IBOutlet var doseMedLabel: UILabel!
    
    
    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateLabels), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _ = updateLabels()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(updateLabels())
    }
    
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    @objc func updateLabels() -> NCUpdateResult {
        self.view.backgroundColor = UIColor.clear
        
        guard let data = defaults.value(forKey: "todayData") as? [String: AnyObject],
              let dateString = data["dateString"] as? String else {
            
            NSLog("Widget", "Today extension data: %@", [defaults.value(forKey: "todayData")])
            let string = NSMutableAttributedString(string: "Couldn't update")
            string.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 24.0, weight: UIFont.Weight.light), range: NSMakeRange(0, string.length))
            
            topConstraint.constant = 16.0
            doseMainLabel.attributedText = string
            doseMedLabel.text = nil
            return NCUpdateResult.newData
        }
        
        if let details = data["medString"] as? String {
            let string = NSMutableAttributedString(string: dateString)
            string.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 50.0, weight: UIFont.Weight.thin), range: NSMakeRange(0, string.length))
            string.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.medGray1, range: NSMakeRange(0, string.length))
            
            // Accomodate 24h times
            let range = (dateString.contains("AM")) ? dateString.range(of: "AM") : dateString.range(of: "PM")
            if let range = range {
                let pos = dateString.distance(from: dateString.startIndex, to: range.lowerBound)
                string.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 22.0), range: NSMakeRange(pos-1, 3))
                string.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.medGray2, range: NSMakeRange(pos-1, 3))
            }
            
            topConstraint.constant = 10.0
            doseMainLabel.attributedText = string
            doseMedLabel.text = details
            return NCUpdateResult.newData
        } else {
            let fontSize: CGFloat = (dateString == "Overdue") ? 32.0 : 24.0
            
            let string = NSMutableAttributedString(string: dateString)
            string.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.light), range: NSMakeRange(0, string.length))
            
            if dateString == "Overdue" {
                self.view.backgroundColor = UIColor.medRed
                string.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: NSMakeRange(0, string.length))
            } else {
                string.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.medGray1, range: NSMakeRange(0, string.length))
            }
            

            topConstraint.constant = 16.0
            doseMainLabel.attributedText = string
            doseMedLabel.text = nil
            return NCUpdateResult.newData
        }
    }
    
    @IBAction func launchApp() {
        if let url = URL(string: "medicine://") {
            self.extensionContext?.open(url, completionHandler: nil)
        }
    }
}
