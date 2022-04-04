
import Foundation
import StoreKit
import SwiftUI


class StoreManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver  {
    
    
    
    // MARK: - PROPERTY
    @Published var transactionState: SKPaymentTransactionState?
    @Published var isPurchased: Bool = false
    @Published var isLoaded:Bool = false
    @AppStorage("stars") var stars: Int = 7
    @Published var myProducts = [SKProduct]()
    var request: SKProductsRequest!
    
    
    
    
    // MARK: - FUNCTION
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        isPurchased = false
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                transactionState = .purchasing
            case .purchased:
                UserDefaults.standard.setValue(true, forKey: transaction.payment.productIdentifier)
                debugPrint("아이디",transaction.payment.productIdentifier)
                switch transaction.payment.productIdentifier{
                case "star10" :
                    stars = stars + 10
                case "star20" :
                    stars = stars + 20
                case "star50" :
                    stars = stars + 50
                default:
                    print("계산안됨")
                }
                isPurchased = true
                
                queue.finishTransaction(transaction)
                transactionState = .purchased
            case .restored:
                UserDefaults.standard.setValue(true, forKey: transaction.payment.productIdentifier)
                queue.finishTransaction(transaction)
                transactionState = .restored
            case .failed, .deferred:
                print("Payment Queue Error: \(String(describing: transaction.error))")
                    queue.finishTransaction(transaction)
                    transactionState = .failed
                    default:
                    queue.finishTransaction(transaction)
            }
        }
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("Did receive response")
        
        if !response.products.isEmpty {
            for fetchedProduct in response.products {
                DispatchQueue.main.async {
                    self.myProducts.append(fetchedProduct)
                }
            }
        }
        
        for invalidIdentifier in response.invalidProductIdentifiers {
            print("Invalid identifiers found: \(invalidIdentifier)")
        }
        DispatchQueue.main.async {
            self.isLoaded = true
            
        }
    }
    
    
    func getProducts(productIDs: [String]) {
        isLoaded = false
        print("Start requesting products ...")
        let request = SKProductsRequest(productIdentifiers: Set(productIDs))
        request.delegate = self
        request.start()
    }
    
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Request did fail: \(error)")
    }
    
    
    
    func purchaseProduct(product: SKProduct) {
        if SKPaymentQueue.canMakePayments() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        } else {
            print("User can't make payment.")
        }
    }
}
