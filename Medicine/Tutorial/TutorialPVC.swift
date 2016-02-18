//
//  TutorialPVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-16.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

class TutorialPVC: UIPageViewController, UIPageViewControllerDataSource {
    
    var tutorialPages = ["This", "is", "a", "tutorial"]
    
    
    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup view, and remove navigation bar shadow
        self.view.backgroundColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        // Setup page control
        let appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = UIColor(white: 0, alpha: 0.2)
        appearance.currentPageIndicatorTintColor = UIColor.whiteColor()
        appearance.frame.offsetInPlace(dx: 0.0, dy: -100.0)
        
        // Setup page view controller
        dataSource = self
        
        // Setup first tutorial page
        if tutorialPages.count > 0 {
            if let first = getPage(0) {
                setViewControllers([first], direction: .Forward, animated: false, completion: nil)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Page view controller data source
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return tutorialPages.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        let tutorial = viewController as! TutorialContentVC
        let index = tutorial.index + 1
        
        if index >= tutorialPages.count {
            setBackgroundColour(true)
        }
        
        if index < tutorialPages.count {
            return getPage(index)
        }
        
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        let tutorial = viewController as! TutorialContentVC
        let index = tutorial.index - 1
        
        if index < tutorialPages.count {
            setBackgroundColour(false)
        }
        
        if index >= 0 {
            return getPage(index)
        }
        
        return nil
    }
    
    func setBackgroundColour(flag: Bool) {
        switch (flag) {
        case true:
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.navigationController?.navigationBar.barTintColor = UIColor.blackColor()
                self.view.backgroundColor = UIColor.blackColor()
            })
        default:
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.navigationController?.navigationBar.barTintColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
                self.view.backgroundColor = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
            })
        }
    }

    
    // MARK: - Helper methods
    func getPage(index: Int) -> TutorialContentVC? {
        if index < tutorialPages.count {
            let tutorial = self.storyboard!.instantiateViewControllerWithIdentifier("TutorialContentVC") as! TutorialContentVC
            tutorial.index = index
            tutorial.tutorialTitle = tutorialPages[index]
            return tutorial
        }
        
        return nil
    }
    
}