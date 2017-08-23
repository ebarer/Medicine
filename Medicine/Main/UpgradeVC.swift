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
    let purchaseColour = UIColor(red: 1, green: 0, blue: 51/255, alpha: 1.0)
    
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Style purchase button
        purchaseButton.layer.cornerRadius = 4
        purchaseButton.layer.borderWidth = 1
        purchaseButton.layer.borderColor = purchaseColour.cgColor
        purchaseButton.tintColor = purchaseColour
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        requestProductInfo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
        
        if let count = products?.count, count > 0 {
            // Set purchase label
            if let upgrade = products?.first {
                purchaseButton.setTitle(upgrade.localizedPrice(), for: UIControlState())
            }
        }
    }

    
    @IBAction func purchaseFullVersion() {
        if let count = products?.count, count > 0 {
            if let upgrade = products?.first {
                if upgrade.productIdentifier == productID {
                    // Modify UI elements
                    purchaseButton.isEnabled = false
                    purchaseButton.setTitle("Purchasing...", for: UIControlState.disabled)
                    restoreButton.isEnabled = false
                    purchaseIndicator.startAnimating()
                    
                    // Process transaction
                    if SKPaymentQueue.canMakePayments() {
                        SKPaymentQueue.default().add(SKPayment(product: upgrade))
                    }
                }
            }
        }
    }
    
    @IBAction func restoreFullVersion(_ sender: AnyObject) {
        // Modify UI elements
        purchaseButton.isEnabled = false
        restoreButton.isEnabled = false
        restoreButton.setTitle("Restoring...", for: UIControlState.disabled)
        purchaseIndicator.startAnimating()
        
        // Process transaction
        if SKPaymentQueue.canMakePayments() {
            SKPaymentQueue.default().restoreCompletedTransactions()
        }
    }
    

    // MARK: - Navigation
    
    @IBAction func cancel(_ sender: AnyObject?) {
        dismiss(animated: true, completion: nil)
    }    

}

extension SKProduct {
    
    func localizedPrice() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)!
    }
    
}
