
import Foundation
import StoreKit
import SwiftUI



class StoreManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver  {
    
    
    
    // MARK: - PROPERTY
    @Published var transactionState: SKPaymentTransactionState?
    @Published var isPurchased: Bool = false
    @Published var isLoaded:Bool = false
    
    
    @Published var myProducts = [SKProduct]()
    var request: SKProductsRequest!
    
   
    // MARK: - FUNCTION
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
       
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                transactionState = .purchasing
            case .purchased:
                UserDefaults.standard.setValue(true, forKey: transaction.payment.productIdentifier)
                debugPrint("아이디",transaction.payment.productIdentifier)
                switch transaction.payment.productIdentifier{
                case "star10" :
                    debugPrint("별 10개",UserDefaults.standard.integer(forKey: AppStorageKeys.stars))
//
                    UserDefaults.standard.setValue(UserDefaults.standard.integer(forKey: AppStorageKeys.stars) + 10, forKey: AppStorageKeys.stars)
                case "star20" :
                    
                    debugPrint("별 20개",UserDefaults.standard.integer(forKey: AppStorageKeys.stars))
//
                    UserDefaults.standard.setValue(UserDefaults.standard.integer(forKey: AppStorageKeys.stars) + 20, forKey: AppStorageKeys.stars)
                case "star50" :
                    
                    debugPrint("별 50개",UserDefaults.standard.integer(forKey: AppStorageKeys.stars))
//
                    UserDefaults.standard.setValue(UserDefaults.standard.integer(forKey: AppStorageKeys.stars) + 50, forKey: AppStorageKeys.stars)
                default:
                    print("계산안됨")
                }
                isPurchased.toggle()
               
                UserDefaults.standard.synchronize()
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
//                    print("내용물들: \(fetchedProduct.productIdentifier)")
                    self.myProducts.sort(by: {$0.productIdentifier < $1.productIdentifier})
                  
                    
                 
                }
            }
          
            
        }
       
        
        for invalidIdentifier in response.invalidProductIdentifiers {
            print("Invalid identifiers found: \(invalidIdentifier)")
        }
        
        
        
        DispatchQueue.main.async {
            self.isLoaded = true
            print("재배열 : \(self.myProducts[0].productIdentifier)")
            print("재배열 : \(self.myProducts[1].productIdentifier)")
            print("재배열 : \(self.myProducts[2].productIdentifier)")
        }
    }
    
   
    
    
    func getProducts(productIDs: [String]) {
        isLoaded = false
        print("Start requesting products ...", UserDefaults.standard.integer(forKey: AppStorageKeys.stars))
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
