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
    var products: [SKProduct]?
    
    
    // MARK: - Outlets
    
    @IBOutlet var purchaseButton: UIButton!
    @IBOutlet var restoreButton: UIButton!
    @IBOutlet var purchaseIndicator: UIActivityIndicatorView!
    
    
    // MARK: - Helper variable
    let purchaseGreen = UIColor(red: 29.0/255, green: 159.0/255, blue: 25.0/255, alpha: 1.0)
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Style purchase button
        purchaseButton.layer.cornerRadius = 4
        purchaseButton.layer.borderWidth = 1
        purchaseButton.layer.borderColor = purchaseGreen.CGColor
        purchaseButton.tintColor = purchaseGreen
    }
    
    override func viewWillAppear(animated: Bool) {
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
            // ## Debug
            print("Cannot perform In App Purchases.")
        }
    }
    
    
    // Mark: - Purchase methods
    
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        products = response.products
        
        // Set purchase label
        if let upgrade = products?[0] {
            purchaseButton.setTitle(upgrade.localizedPrice(), forState: UIControlState.Normal)
        }
    }

    
    @IBAction func purchaseFullVersion() {
        if let upgrade = products?[0] {
            if upgrade.productIdentifier == productID {
                // Modify UI elements
                purchaseButton.enabled = false
                purchaseButton.setTitle("Purchasing...", forState: UIControlState.Disabled)
                restoreButton.enabled = false
                purchaseIndicator.startAnimating()
                
                // Process transaction
                if SKPaymentQueue.canMakePayments() {
                    SKPaymentQueue.defaultQueue().addPayment(SKPayment(product: upgrade))
                }
            }
        }
    }
    
    @IBAction func restoreFullVersion(sender: AnyObject) {
        // Modify UI elements
        purchaseButton.enabled = false
        restoreButton.enabled = false
        restoreButton.setTitle("Restoring...", forState: UIControlState.Disabled)
        purchaseIndicator.startAnimating()
        
        // Process transaction
        if SKPaymentQueue.canMakePayments() {
            SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
        }
    }
    

}

extension SKProduct {
    
    func localizedPrice() -> String {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        formatter.locale = self.priceLocale
        return formatter.stringFromNumber(self.price)!
    }
    
}
