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
    @IBOutlet var doseMainLabel: UILabel!
    @IBOutlet var doseMedLabel: UILabel!
    
    
    // MARK: - View methods
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: OperationQueue.main) { _ in
            _ = self.updateLabels()
        }
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
    
    func updateLabels() -> NCUpdateResult {
        if let todayData = defaults.value(forKey: "todayData") {
            let data = todayData as! [String: AnyObject]
            
            // Show next dose
            if let date = data["date"] {
                if ((date as! Date).compare(Date()) == .orderedDescending && cal.isDateInToday(date as! Date)) {
                    let string = NSMutableAttributedString(string: data["dateString"] as! String)
                    string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 50.0, weight: UIFont.Weight.ultraLight), range: NSMakeRange(0, string.length-2))
                    string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 20.0), range: NSMakeRange(string.length-2, 2))
                    
                    doseMainLabel.attributedText = string
                    doseMedLabel.text = (data["medString"] as? String)

                    return NCUpdateResult.newData
                }
            }
            
            let string = NSMutableAttributedString(string: data["dateString"] as! String)
            string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 24.0, weight: UIFont.Weight.thin), range: NSMakeRange(0, string.length))

            doseMainLabel.attributedText = string
            doseMedLabel.text = nil

            return NCUpdateResult.newData
        }
        
        let string = NSMutableAttributedString(string: "Couldn't update")
        string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.thin), range: NSMakeRange(0, string.length))
        
        doseMainLabel.attributedText = string
        doseMedLabel.text = nil

        return NCUpdateResult.newData
    }
    
    @IBAction func launchApp() {
        if let url = URL(string: "medicine://") {
            self.extensionContext?.open(url, completionHandler: nil)
        }
    }
}
