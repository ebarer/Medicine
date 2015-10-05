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

    let defaults = NSUserDefaults(suiteName: "group.com.ebarer.Medicine")!
    let cal = NSCalendar.currentCalendar()
    
    
    // MARK: - Outlets
    @IBOutlet var doseDescriptionLabel: UILabel!
    @IBOutlet var doseMainLabel: UILabel!
    @IBOutlet var doseMedLabel: UILabel!
    
    
    // MARK: - View methods
    override func viewDidLoad() {
        self.preferredContentSize = CGSizeMake(0, 130.0);
        
        NSNotificationCenter.defaultCenter().addObserverForName(NSUserDefaultsDidChangeNotification, object: nil, queue: NSOperationQueue.mainQueue()) { _ in
            self.updateLabels()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        updateLabels()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        completionHandler(updateLabels())
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
    func updateLabels() -> NCUpdateResult {
        if let todayData = defaults.valueForKey("todayData") {
            let data = todayData as! [String: AnyObject]
            
            // If no doses taken, but medication count != 0
//            if (data["dateString"] as? String) == "Take first dose" {
//                let string = NSMutableAttributedString(string: "No doses scheduled")
//                string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))
//                
//                doseDescriptionLabel.text = nil
//                doseMainLabel.attributedText = string
//                doseMedLabel.text = nil
//            }

            if let date = data["date"] {
                // Dose overdue
                if (date as! NSDate).compare(NSDate()) == .OrderedAscending {
                    let string = NSMutableAttributedString(string: "Overdue dose")
                    string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))

                    doseDescriptionLabel.text = nil
                    doseMainLabel.attributedText = string
                    doseMedLabel.text = nil
                    return NCUpdateResult.NewData
                }
                // No doses due today
                else if !cal.isDateInToday((date as! NSDate)) {
                    let string = NSMutableAttributedString(string: "No more doses today")
                    string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))
                    
                    doseDescriptionLabel.text = nil
                    doseMainLabel.attributedText = string
                    doseMedLabel.text = nil
                    return NCUpdateResult.NewData
                }
                // Show next dose
                else {
                    if let dateString = data["dateString"] {
                        let string = NSMutableAttributedString(string: (dateString as! String))
                        string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(50.0, weight: UIFontWeightUltraLight), range: NSMakeRange(0, string.length-2))
                        string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0), range: NSMakeRange(string.length-2, 2))
                        doseMainLabel.attributedText = string
                    }
                    
                    doseDescriptionLabel.text = (data["descriptionString"] as? String)
                    doseMedLabel.text = (data["medString"] as? String)
                    return NCUpdateResult.NewData
                }
            } else {
                let string = NSMutableAttributedString(string: "No doses scheduled")
                string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))
                
                doseDescriptionLabel.text = nil
                doseMainLabel.attributedText = string
                doseMedLabel.text = nil
                return NCUpdateResult.NewData
            }
        } else {
            let string = NSMutableAttributedString(string: "You have no medications")
            string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))
            doseDescriptionLabel.text = nil
            doseMainLabel.attributedText = string
            doseMedLabel.text = nil
            doseDescriptionLabel.text = nil
            return NCUpdateResult.NewData
        }
    }
    
    @IBAction func launchApp() {
        if let url = NSURL(string: "medicine://") {
            self.extensionContext?.openURL(url, completionHandler: nil)
        }
    }
}