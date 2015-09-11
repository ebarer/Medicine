//
//  UpgradeVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-10.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import StoreKit

class UpgradeVC: UIViewController, SKProductsRequestDelegate {

    let productID = "com.ebarer.Medicine.Unlock"
    var products = [SKProduct]()
    
    
    // MARK: - Outlets
    
    @IBOutlet var purchaseButton: UIButton!

    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestProductInfo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    // MARK: - Navigation
    
    @IBAction func cancel(sender: AnyObject?) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: - Store kit delegate/observer
    
    func requestProductInfo() {
        if SKPaymentQueue.canMakePayments() {
            let productRequest = SKProductsRequest(productIdentifiers: Set([productID]))
            productRequest.delegate = self
            productRequest.start()
        } else {
            print("Cannot perform In App Purchases.")
        }
    }
    
    
    // Mark: - Purchase methods
    
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        products = response.products

        let upgrade = products[0]
        print("Title: \(upgrade.localizedTitle)")
        print("Description: \(upgrade.localizedDescription)")
        print("Price: \(upgrade.price)")
        print("ID: \(upgrade.productIdentifier)")
    }
    
    @IBAction func purchaseFullVersion() {
        if self.products[0].productIdentifier == productID {
            purchaseButton.enabled = false
            purchaseButton.titleLabel?.text = "Purchasing..."
            SKPaymentQueue.defaultQueue().addPayment(SKPayment(product: self.products[0]))
        }
    }

}
