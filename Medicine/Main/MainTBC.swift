//
//  MainTBC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-21.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices

class MainTBC: UITabBarController, UITabBarControllerDelegate {
    
    // MARK: - Helper variables
    let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    let cdStack = (UIApplication.shared.delegate as! AppDelegate).stack
    let defaults = UserDefaults(suiteName: "group.com.ebarer.Medicine")!
    var selectedVC: UIViewController? = nil
    
    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
        // Set tab bar controller
        tabBar.barStyle = .default
        tabBar.tintColor = UIColor.medRed
        
        // Add observers for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(doseNotification(_:)), name: NSNotification.Name(rawValue: "doseNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refillNotification(_:)), name: NSNotification.Name(rawValue: "refillNotification"), object: nil)
        
        // Add observers for notification actions
        NotificationCenter.default.addObserver(self, selector: #selector(takeDoseAction(_:)), name: NSNotification.Name(rawValue: "takeDoseAction"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(snoozeReminderAction(_:)), name: NSNotification.Name(rawValue: "snoozeReminderAction"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refillAction(_:)), name: NSNotification.Name(rawValue: "refillAction"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onboarding()
    }
    
    func onboarding() {
        let dictionary = Bundle.main.infoDictionary!
//        let version = dictionary["CFBundleShortVersionString"] as! String
        let version = dictionary["CFBundleVersion"] as! String
        let fetchRequest: NSFetchRequest<Medicine> = Medicine.fetchRequest()
        
        // If first launch and medication count is 0, show "Welcome" screen
        if defaults.bool(forKey: "finishedFirstLaunch") == false {
            if let count = try? cdStack.context.count(for: fetchRequest), count == 0 {
                defaults.set(true, forKey: "finishedFirstLaunch")
                defaults.setValue(version, forKey: "version")
                defaults.synchronize()
                
                print("Onboarding: first launch")
                
                self.performSegue(withIdentifier: "onboardingFirstLaunch", sender: self)
                return
            }
        }
            
        // Otherwise, on new version, show "New Features" screen
        if defaults.string(forKey: "version") != version {
            defaults.set(true, forKey: "finishedFirstLaunch")
            defaults.setValue(version, forKey: "version")
            defaults.synchronize()
            
            print("Onboarding: new features")
            
            self.performSegue(withIdentifier: "onboardingNewFeatures", sender: self)
        } else {
            print("No onboarding necessary.")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Tab delegate
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewController.isKind(of: UISplitViewController.self) {
            self.tabBar.barStyle = .default
            
            if viewController == selectedVC {
                let navVC = (viewController as! UISplitViewController).childViewControllers[0] as! UINavigationController
                navVC.popToRootViewController(animated: true)
            }
        } else {
            self.tabBar.barStyle = .default
        }
        
        selectedVC = viewController
    }
    
    // MARK: - Notification observers
    @objc func doseNotification(_ notification: Notification) {
        if let id = notification.userInfo!["id"] as? String {
            let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
            request.predicate = NSPredicate(format: "medicineID == %@", argumentArray: [id])
            if let med = (try? cdStack.context.fetch(request))?.first {
                print("doseNotification triggered for \(med.name ?? "unknown medicine")")
                
                let message = String(format:"Time to take %g %@ of %@", med.dosage, med.dosageUnit.units(med.dosage), med.name!)
                
                let alert = UIAlertController(title: "Take \(med.name!)", message: message, preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Take Dose", style:  UIAlertActionStyle.destructive, handler: {(action) -> Void in
                    self.performSegue(withIdentifier: "addDose", sender: med)
                }))
                
                if med.lastDose != nil {
                    alert.addAction(UIAlertAction(title: "Snooze", style: UIAlertActionStyle.default, handler: {(action) -> Void in
                        med.snoozeNotification()
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
                    }))
                }
                
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: {(action) -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
                }))
                
                alert.view.tintColor = UIColor.gray
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @objc func refillNotification(_ notification: Notification) {
        if let id = notification.userInfo!["id"] as? String {
            let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
            request.predicate = NSPredicate(format: "medicineID == %@", argumentArray: [id])
            if let med = (try? cdStack.context.fetch(request))?.first {
                print("refillNotification triggered for \(med.name ?? "unknown medicine")")
                
                var message = "You are running low on \(med.name!) and should refill soon."
                
                if med.prescriptionCount < med.dosage {
                    message = "You don't have enough \(med.name!) to take your next dose."
                } else if let count = med.refillDaysRemaining(), med.prescriptionCount > 0 && count > 0 {
                    message = "You currently have enough \(med.name!) for about \(count) \(count == 1 ? "day" : "days") and should refill soon."
                }
                
                let alert = UIAlertController(title: "Reminder to Refill \(med.name!)", message: message, preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Refill", style:  UIAlertActionStyle.destructive, handler: {(action) -> Void in
                    self.performSegue(withIdentifier: "refillPrescription", sender: med)
                }))
                
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: nil))
                
                alert.view.tintColor = UIColor.gray
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Action observers
    @objc func takeDoseAction(_ notification: Notification) {
        NSLog("takeDoseAction received", [])
        if let id = notification.userInfo!["id"] as? String {
            let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
            request.predicate = NSPredicate(format: "medicineID == %@", argumentArray: [id])
            if let medication = try? cdStack.context.fetch(request), let med = medication.first {
                let dose = Dose(insertInto: cdStack.context)
                dose.date = Date()
                dose.dosage = med.dosage
                dose.dosageUnitInt = med.dosageUnitInt
                med.addDose(dose)
                
                // Check if medication needs to be refilled
                let refillTime = defaults.integer(forKey: "refillTime")
                if med.needsRefill(limit: refillTime) {
                    med.sendRefillNotification()
                }
                
                cdStack.save()
                NSLog("takeDoseAction performed", [])

                appDelegate.setDynamicShortcuts()
                appDelegate.updateBadgeCount()
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
            }
        }
    }
    
    @objc func snoozeReminderAction(_ notification: Notification) {
        NSLog("snoozeReminderAction received", [])
        if let id = notification.userInfo!["id"] as? String {
            let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
            request.predicate = NSPredicate(format: "medicineID == %@", argumentArray: [id])
            if let medication = try? cdStack.context.fetch(request), let med = medication.first {
                med.snoozeNotification()
                appDelegate.setDynamicShortcuts()
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshMain"), object: nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshView"), object: nil)
                NSLog("snoozeReminderAction performed for %@", [med.name!])
            }
        }
    }
    
    @objc func refillAction(_ notification: Notification) {
        NSLog("refillAction received", [])
        if let id = notification.userInfo!["id"] as? String {
            let request: NSFetchRequest<Medicine> = Medicine.fetchRequest()
            request.predicate = NSPredicate(format: "medicineID == %@", argumentArray: [id])
            if let med = (try? cdStack.context.fetch(request))?.first {
                performSegue(withIdentifier: "refillPrescription", sender: med)
                NSLog("refillAction performed for %@", [med.name!])
            }
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addDose" {
            if let vc = segue.destination.childViewControllers[0] as? AddDoseTVC {
                if let med = sender as? Medicine {
                    vc.med = med
                }
            }
        }
        
        if segue.identifier == "refillPrescription" {
            if let vc = segue.destination.childViewControllers[0] as? AddRefillTVC {
                if let med = sender as? Medicine {
                    vc.med = med
                }
            }
        }
    }
}

extension UITabBarController {
    func setTabBarVisible(_ visible: Bool, animated: Bool) {
        if tabBarIsVisible() != visible {
            // Determine frame calculation
            let frame = self.tabBar.frame
            let height = frame.size.height
            let offsetY = (visible ? -height : height)

            UIView.animate(withDuration: animated ? 0.3 : 0.0, animations: {
                // Change frame of TabBar
                self.tabBar.frame = frame.offsetBy(dx: 0, dy: offsetY)
                
                // Change frame of UITabBarController
                self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height + offsetY)
                self.view.setNeedsDisplay()
                self.view.layoutIfNeeded()
            }) 
        }
    }
    
    func tabBarIsVisible() -> Bool {
        return self.tabBar.frame.origin.y < self.view.frame.maxY
    }
}
