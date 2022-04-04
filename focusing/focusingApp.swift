//
//  focusingApp.swift
//  focusing
//
//  Created by 고종찬 on 2022/03/27.
//

import SwiftUI
import StoreKit

@main
struct focusingApp: App {
  
    init() {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .black
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .previewInterfaceOrientation(.portrait)

                
               
        }
    }
}
