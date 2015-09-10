//
//  UpgradeVC.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-09-10.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit
import StoreKit

class UpgradeVC: UIViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    // MARK: - IAP variables
    
    var products = [SKProduct]()
    var transacting = false

    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestProductInfo()
        //requestReceipt()
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
            let productRequest = SKProductsRequest(productIdentifiers: Set(["com.ebarer.Medicine.Unlock"]))
            productRequest.delegate = self
            productRequest.start()
        } else {
            print("Cannot perform In App Purchases.")
        }
    }
    
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        products = response.products
        print(products[0].localizedTitle)
    }
    
    func requestReceipt() {
        let request = SKReceiptRefreshRequest()
        request.delegate = self
        request.start()
    }
    
    func purchaseFullVersion() {
        if !transacting && self.products[0].productIdentifier == "com.ebarer.Medicine.Unlock" {
            SKPaymentQueue.defaultQueue().addPayment(SKPayment(product: self.products[0]))
            transacting = true
        }
    }
    
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            if transaction.transactionState == SKPaymentTransactionState.Purchased {
                // unlockFullVersion()
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
            }

            transacting = false
        }
    }

    
}
