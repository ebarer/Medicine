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

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        purchaseButton.layer.cornerRadius = 10.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        requestProductInfo()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Store kit delegate/observer
    func requestProductInfo() {
        if SKPaymentQueue.canMakePayments() {
            NSLog("IAP", "Starting IAP process")
            let productRequest = SKProductsRequest(productIdentifiers: Set([productID]))
            productRequest.delegate = self
            productRequest.start()
        } else {
            NSLog("IAP", "Error: Cannot perform IAP: user cannot make payments")
        }
    }
    
    
    // Mark: - Purchase methods
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
        
        guard let _ = products?.count, let upgrade = products?.first else {
            return
        }
        
        purchaseButton.setTitle(upgrade.localizedPrice, for: UIControl.State())
    }

    
    @IBAction func purchaseFullVersion() {
        // Check that user can make purchases
        guard SKPaymentQueue.canMakePayments() == true else {
            NSLog("IAP", "Error: Cannot perform IAP: user cannot make payments")
            displayPurchaseFailureAlert()
            return
        }
        
        // Check that there are products to purchase
        guard let _ = products?.count, let upgrade = products?.first else {
            NSLog("IAP", "Error: Cannot perform IAP: no products available for purchase")
            displayPurchaseFailureAlert()
            return
        }

        if upgrade.productIdentifier == productID {
            // Modify UI elements
            purchaseButton.isEnabled = false
            purchaseButton.setTitle("Purchasing...", for: UIControl.State.disabled)
            restoreButton.isEnabled = false
            purchaseIndicator.startAnimating()
            
            // Process transaction
            SKPaymentQueue.default().add(SKPayment(product: upgrade))
        }
    }
    
    func displayPurchaseFailureAlert() {
        let alert = UIAlertController(title: "Purchased failed",
                                      message: "Could not complete purchase at this time.",
                                      preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func restoreFullVersion(_ sender: AnyObject) {
        NSLog("IAP", "Attempting to restore full version from previous purchase")
        
        // Modify UI elements
        purchaseButton.isEnabled = false
        restoreButton.isEnabled = false
        restoreButton.setTitle("Restoring...", for: UIControl.State.disabled)
        purchaseIndicator.startAnimating()
        
        // Process transaction
        if SKPaymentQueue.canMakePayments() {
            SKPaymentQueue.default().restoreCompletedTransactions()
        } else {
            NSLog("IAP", "Error: Cannot restore full version: user unable to make payments")
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
