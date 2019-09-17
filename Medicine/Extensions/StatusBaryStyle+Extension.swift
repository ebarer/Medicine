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
        return .default
    }
}

extension UISplitViewController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}

extension UINavigationController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
//        return topViewController?.preferredStatusBarStyle ?? .lightContent
    }
}
