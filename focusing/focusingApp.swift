//
//  focusingApp.swift
//  focusing
//
//  Created by 고종찬 on 2022/03/27.
//

import SwiftUI
import StoreKit
import AVFoundation
import Foundation

@main
struct focusingApp: App {
    
    
    
    init() {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .black
    }
    
    
    
    @AppStorage("agreed") var isAgreed: Bool = false
    
    @AppStorage("cameraNotAuthorized") var cameraNotAuthorized: Bool = true
    
    
    var body: some Scene {
        
        
        WindowGroup {
            
            
            
            
            ContentView(model: CameraViewModel())
                .previewInterfaceOrientation(.portrait)
                .onAppear(perform: {
                    if !isAgreed{
                        
                        UserDefaults.standard.setValue(5, forKey: AppStorageKeys.stars)
                    }
                    
                    
                    // first checking camerahas got permission...
                    switch AVCaptureDevice.authorizationStatus(for: .video) {
                    case .authorized:
                        cameraNotAuthorized = false
                        
                        return
                        // Setting Up Session
                    case .notDetermined:
                        // retusting for permission....
                        AVCaptureDevice.requestAccess(for: .video) { (status) in
                            
                            if status{
                                cameraNotAuthorized = false
                            }else{
                                cameraNotAuthorized  = true
                            }
                        }
                    case .denied:
                        cameraNotAuthorized = true
                        
                        return
                        
                    default:
                        return
                    }
                    
                    
                })
        }
    }
}

