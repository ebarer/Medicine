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
    @IBOutlet var doseCounterLabel: UILabel!
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

    func updateLabels() -> NCUpdateResult {
        if let dose = defaults.valueForKey("dose") {
            guard let time = defaults.valueForKey("doseDate") else { return NCUpdateResult.Failed }
            
            let string = NSMutableAttributedString(string: time as! String)
            let len = string.length
            string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(50.0, weight: UIFontWeightUltraLight), range: NSMakeRange(0, len-2))
            string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0), range: NSMakeRange(len-2, 2))
            doseCounterLabel.attributedText = string
            doseMedLabel.text = (dose as! String)
            
            return NCUpdateResult.NewData
        } else {
            guard let text = defaults.valueForKey("doseDate") else { return NCUpdateResult.Failed }
            
            let string = NSMutableAttributedString(string: text as! String)
            string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(24.0, weight: UIFontWeightThin), range: NSMakeRange(0, string.length))
            doseCounterLabel.attributedText = string
            doseMedLabel.text = nil
            
            return NCUpdateResult.NewData
        }
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
    }
    
}
