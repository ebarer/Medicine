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

    let cal = NSCalendar.currentCalendar()
    let defaults = NSUserDefaults(suiteName: "group.com.ebarer.Medicine")!
    
    
    // MARK: - Outlets
    @IBOutlet var doseMainLabel: UILabel!
    @IBOutlet var doseMedLabel: UILabel!
    
    
    // MARK: - View methods
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserverForName(NSUserDefaultsDidChangeNotification, object: nil, queue: NSOperationQueue.mainQueue()) { _ in
            self.updateLabels()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
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
            
            // Show next dose
            if let date = data["date"] {
                if ((date as! NSDate).compare(NSDate()) == .OrderedDescending && cal.isDateInToday(date as! NSDate)) {
                    let string = NSMutableAttributedString(string: data["dateString"] as! String)
                    string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(50.0, weight: UIFontWeightUltraLight), range: NSMakeRange(0, string.length-2))
                    string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(20.0), range: NSMakeRange(string.length-2, 2))
                    
                    doseMainLabel.attributedText = string
                    doseMedLabel.text = (data["medString"] as? String)

                    return NCUpdateResult.NewData
                }
            }
            
            let string = NSMutableAttributedString(string: data["dateString"] as! String)
            string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))

            doseMainLabel.attributedText = string
            doseMedLabel.text = nil

            return NCUpdateResult.NewData
        }
        
        let string = NSMutableAttributedString(string: "Couldn't update")
        string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(12.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))
        
        doseMainLabel.attributedText = string
        doseMedLabel.text = nil

        return NCUpdateResult.NewData
    }
    
    @IBAction func launchApp() {
        if let url = NSURL(string: "medicine://") {
            self.extensionContext?.openURL(url, completionHandler: nil)
        }
    }
}
