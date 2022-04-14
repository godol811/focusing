//
//  ContentView.swift
//  focusing
//
//  Created by 고종찬 on 2022/03/27.
//

import SwiftUI
import AppTrackingTransparency
import AudioToolbox
import AVFoundation


struct ContentView: View {
    @ObservedObject private(set) var model: CameraViewModel
    
    init(model: CameraViewModel) {
        self.model = model
    }
    
    // MARK: - PROPERTY
    @AppStorage("onboarding") var isOnboardingViewActive: Bool = false
    @AppStorage("cameraNotAuthorized") var cameraNotAuthorized: Bool = true
    
    
    @AppStorage("agreed") var isAgreed: Bool = false
    //    @AppStorage(AppStorageKeys.stars) var stars: Int = 5
    @State var stars = UserDefaults.standard.integer(forKey: AppStorageKeys.stars)
    
    
//    @AppStorage("cameraNotAuthorized") var cameraNotAuthorized: Bool = true
    
    @State var remindCameraAuthorizedAlert = false
    
    @State var cameraAuthorizedAlert = false
    
    let timer = Timer.publish(every: 1.0, on: .current, in: .common).autoconnect()
    
    // MARK: - FUNCTION
    
    var body: some View {
        
        
        if !cameraNotAuthorized{
            
            
            
            NavigationView{
                ZStack{
                    if model.isZeroStarAlert{
                        EmptyView()
                    }else{
                        OnBoardingView()
                        
                            .onAppear( perform: {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                                    isOnboardingViewActive = true
                                })
                            })
                        
                        
                        
                    }
                    
                    
                    VStack{
                        if !isAgreed{
                            BlankView()
                            
                            Spacer()
                            
                            AgreeView()
                            
                        }else{
                            MainView(model: model)
                                .onReceive(timer) { _ in
                                    
                                    DispatchQueue.main.async {
                                        if model.isTimerStart{
                                            
                                            if model.timeRemaining > 0 {
                                                model.timeRemaining -= 1
                                                
                                            }else if model.timeRemaining == 0 {
                                                //                    camera.takePic()
                                                model.perform(action:  .takePhoto)
                                                model.cameraTimerIsZero = true
                                                model.timeRemaining = 3
                                                model.isTimerStart.toggle()
                                                AudioServicesPlaySystemSound(1108)
                                            }
                                            
                                        }
                                        
                                    }
                                }
                            
                            
                        }
                        
                    }//: VSTACK
                    
                    .alert(isPresented: $model.isZeroStarAlert){
                        
                        Alert(title: Text("별이 부족합니다."), message: Text("상점으로 이동하시겠습니까?"), primaryButton: .default(Text("취소")), secondaryButton: .default(Text("확인"), action: {
                            model.moveToShop.toggle()
                        }))
                    }
                    
                    
                    
                }//: ZSTACK
                
            }.navigationBarHidden(true)
            
            
            //앱 투명성 요청
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    ATTrackingManager.requestTrackingAuthorization(completionHandler: { _ in
                    })
                    
                }
            //카메라 접근 권한 요청
            
        }else if cameraNotAuthorized{
            
            Button(action: {
                
                let setting = "app-settings:"
                let settingForm = setting + "root=focusing"
                guard let url = URL(string: settingForm) else { return }
                UIApplication.shared.open(url)
//                cameraAuthorizedAlert = true
                
            }, label: {
                VStack{
                    Image("CameraRequestBox")
                        .resizable()
                        .frame(width: UIScreen.main.bounds.width - 210 , height: 56, alignment: .center)
                        .overlay(
                            Text("카메라 권한 설정하기")
                                .modifier(SemiBold(size:15))
                                .foregroundColor(Color("goldenYellow"))
                        )
                        .padding(.bottom, 10)
                    
                    
                    Text("서비스 이용을 위해 카메라를 ON 해주세요")
                        .modifier(SemiBold(size:12))
                        .foregroundColor(Color("brownGrey"))
                    
                }
            })
            
            
            
            
//                .onAppear(perform: {
//
//
//
//                    cameraAuthorizedAlert  = true
//                    print("확인")
//
//
//
//                })
//                .alert(isPresented: $cameraAuthorizedAlert){
//                    Alert(title: Text("카메라 접근 권한이 필요합니다."), message: Text("설정 화면으로 이동하시겠습니까?"), primaryButton: .default(Text("취소") , action: {
//
//                        remindCameraAuthorizedAlert.toggle()
//
//                    }), secondaryButton: .default(Text("확인"), action: {
//                        let setting = "app-settings:"
//                        let settingForm = setting + "root=focusing"
//                        guard let url = URL(string: settingForm) else { return }
//                        UIApplication.shared.open(url)
//                    }))
//                }
//                .alert(isPresented: $remindCameraAuthorizedAlert){
//                    Alert(title: Text("Focusing을 이용하기 위해서는 카메라 접근 권한이 필요합니다."), message: Text("설정에서 카메라 접근 권한을 허용 해주세요"), dismissButton: .cancel())
//
//                }
            
        }
    }
}



