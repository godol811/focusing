//
//  ContentView.swift
//  focusing
//
//  Created by 고종찬 on 2022/03/27.
//

import SwiftUI
import AppTrackingTransparency

struct ContentView: View {
    
    // MARK: - PROPERTY
    @AppStorage("onboarding") var isOnboardingViewActive: Bool = false
    @AppStorage("agreed") var isAgreed: Bool = false
    @AppStorage("stars") var stars: Int = 7
    
    // MARK: - FUNCTION
    
    var body: some View {
        
        NavigationView{
            ZStack{
                OnBoardingView()
                
                    .onAppear( perform: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                            isOnboardingViewActive = true
                        })
                    })
                
                VStack{
                    if !isAgreed{
                        BlankView()
                        
                        Spacer()
                        
                        AgreeView()
                    }else{
                        MainView()
                        
                    }
                    
                }//: VSTACK
                
                
            }//: ZSTACK
            
        }.navigationBarHidden(true)
        
        
        //앱 투명성 요청
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                ATTrackingManager.requestTrackingAuthorization(completionHandler: { _ in
                })
                
            }
    }
}


