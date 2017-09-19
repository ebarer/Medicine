//
//  StatusBaryStyle+Extension.swift
//  Medicine
//
//  Created by Elliot Barer on 2017-09-19.
//  Copyright © 2017 Elliot Barer. All rights reserved.
//

import UIKit

extension UITabBarController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension UISplitViewController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension UINavigationController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? .lightContent
    }
}
