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
    
    // MARK: - View methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Style purchase button
        purchaseButton.layer.cornerRadius = 4
        purchaseButton.layer.borderWidth = 1
        purchaseButton.layer.borderColor = UIColor.medRed.cgColor
        purchaseButton.tintColor = UIColor.medRed
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
        
        guard let _ = products?.count, let upgrade = products?.first else {
            return
        }
        
        purchaseButton.setTitle(upgrade.localizedPrice, for: UIControlState())
    }

    
    @IBAction func purchaseFullVersion() {
        // Check that user can make purchases
        guard SKPaymentQueue.canMakePayments() == true else {
            displayPurchaseFailureAlert()
            return
        }
        
        // Check that there are products to purchase
        guard let _ = products?.count, let upgrade = products?.first else {            
            displayPurchaseFailureAlert()
            return
        }

        if upgrade.productIdentifier == productID {
            // Modify UI elements
            purchaseButton.isEnabled = false
            purchaseButton.setTitle("Purchasing...", for: UIControlState.disabled)
            restoreButton.isEnabled = false
            purchaseIndicator.startAnimating()
            
            // Process transaction
            SKPaymentQueue.default().add(SKPayment(product: upgrade))
        }
    }
    
    func displayPurchaseFailureAlert() {
        let alert = UIAlertController(title: "Purchased failed",
                                      message: "Could not complete purchase at this time.",
                                      preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
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
    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)!
    }
}
