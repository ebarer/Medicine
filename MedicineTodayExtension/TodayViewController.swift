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
    var nextDose: [String:String]?
    
    
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
            //string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))
            doseMainLabel.text = todayData["counterString"] as? String
            doseMedLabel.text = todayData["medString"] as? String
            doseDescriptionLabel.text = todayData["descriptionString"] as? String
            return NCUpdateResult.NewData
        } else {
            let string = NSMutableAttributedString(string: "You have no medications")
            string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))
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