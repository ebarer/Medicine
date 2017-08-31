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
        guard let data = defaults.value(forKey: "todayData") as? [String: AnyObject] else {
            let string = NSMutableAttributedString(string: "Couldn't update")
            string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.thin), range: NSMakeRange(0, string.length))
            
            doseMainLabel.attributedText = string
            doseMedLabel.text = nil
            return NCUpdateResult.newData
        }
        
        if let dateString = data["dateString"] as? String, let details = data["medString"] as? String {
            let string = NSMutableAttributedString(string: dateString)
            string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 50.0, weight: UIFont.Weight.ultraLight), range: NSMakeRange(0, string.length))
            
            // Accomodate 24h times
            let range = (dateString.contains("AM")) ? dateString.range(of: "AM") : dateString.range(of: "PM")
            if let range = range {
                let pos = dateString.characters.distance(from: dateString.startIndex, to: range.lowerBound)
                string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 22.0), range: NSMakeRange(pos-1, 3))
            }
            
            doseMainLabel.attributedText = string
            doseMedLabel.text = details
            return NCUpdateResult.newData
        }
        
        let string = NSMutableAttributedString(string: data["dateString"] as! String)
        string.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 32.0, weight: UIFont.Weight.thin), range: NSMakeRange(0, string.length))

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
