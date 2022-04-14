//
//  MainView.swift
//  focusing
//
//  Created by 고종찬 on 2022/03/27.
//

import SwiftUI
import StoreKit
import Vision
import AVFoundation


struct MainView: View {
    
    
    //MARK: - FUNCTION
    
    @ObservedObject private(set) var model: CameraViewModel
    
    
    
    
    
    //MARK: - PROPERTY
//    @StateObject var camera = CameraModel()
    @StateObject var storeManager = StoreManager()
//    @State private var timeRemaining = 3
    @State var optionIndex = 0
    @State private var isTexting = false
    @State private var convertedImage:UIImage?
    
    //별이 없는 경우
    @State private var isZeroStarAlert = false
    
    @State var cameraRequest : Bool = false
  
//    @State var stars = UserDefaults.standard.integer(forKey: AppStorageKeys.stars)
    
    
    let productIDs = ["star10","star20","star50"]

    
    var body: some View {
        
        
        
        ZStack{
            
            if model.isDetected{
                
                Image(uiImage: model.detectedImage!)
                    .resizable()
//                    .frame(minWidth: 0, idealWidth: UIScreen.main.bounds.width, maxWidth: .infinity, minHeight: 0, idealHeight: UIScreen.main.bounds.height, maxHeight: .infinity, alignment: .center)
//                    .aspectRatio(contentMode: .fill)
//                    .scaleEffect(0.8)
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
//                    .frame(width: UIScreen.main.bounds.width, alignment: .top)
//                    .background(Color.black)
                    
                
                
                
            }else{
                if !model.isZeroStarAlert || !model.cameraNotAuthorized{
                CameraView(model: model)
                //                DetectedCameraPreview()
                    .edgesIgnoringSafeArea(.all)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                //                .edgesIgnoringSafeArea(.top)
                    .opacity(model.isDetected ? 0 : 1)
                    .onDisappear(perform: {
                        debugPrint("카메라 사라짐")
                     
                    })
                    .onAppear(perform:{
                        debugPrint("카메라 나타남")
                        
                        
                    })
              
                    FaceBoundingBoxView(model: model)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)                    .edgesIgnoringSafeArea(.all)
                    
                }
            }
            
            
            
            if model.isProgressing{
                
                ProgressView()
                    .scaleEffect(3)
                    .frame(width: 80, height: 80)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("tangerine")))
                
                
            }
            
            
            
            
            
            
            // MARK: - BODY
            VStack{
                Spacer()
                ZStack{
                    
                    if model.isTimerStart {
                        
                        Text("\(model.timeRemaining)")
                                .modifier(ExtraBold(size: 150))
                                .foregroundColor(Color("tangerine"))
                                .frame(width: 100, height: 188, alignment: .center)
                                .opacity(model.timeRemaining == 0 ? 0 : 1)
                                .opacity(model.timeRemaining == 3 ? 0 : 1)
                        
                        
                    }
                    
                    
                    if model.isTaken{
                        HStack{
                            Button(action: {
                                model.reTake()
                                //초기화
                                
                            }, label: {
                                Image("back")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                            })
                            .padding(.leading, 57)
                            Spacer()
                            Button(action: {
                                model.requestImage(index: optionIndex)
                            }, label: {
                                Image("go")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                            })
                            .padding(.trailing, 57)
                        }//:HSTACK
                        
                        
                        
                    }
                    
                    
                    
                    
                    
                    if model.errorDetected{
                        
                        Text("정상적으로 작동하지 않았습니다 \n두명의 얼굴을 화면 안에 정확히 위치시켜주세요")
                            .modifier(SemiBold(size: 15))
                            .multilineTextAlignment(.center)
                            .lineSpacing(10)
                        
                            .foregroundColor(Color.white)
                            .padding()
                        
                    }
                }
                
                
                // MARK: - FOOTER
                
                ZStack{
                    BlankView()
                    VStack{
                        ZStack{
                            HStack{
                                NavigationLink(isActive: $model.moveToShop,
                                               
                                               destination: {
                                    InAppPurchaseView(storeManager: storeManager)
                                        .onAppear(perform: {
                                            storeManager.getProducts(productIDs: productIDs)
                                            SKPaymentQueue.default().add(storeManager)
                                            debugPrint( UserDefaults.standard.integer(forKey: AppStorageKeys.stars), "여기" )
                                        })
                                    
                                }, label: {
                                    VStack{
                                        
                                        HStack{
                                            Image("Star")
                                                .resizable()
                                                .frame(width: 30, height: 30)
                                                .padding(.leading, 13)
                                            Text("\(UserDefaults.standard.integer(forKey: AppStorageKeys.stars))")
                                                .modifier(Medium(size: 20))
                                                .foregroundColor(.white)
                                            Spacer()
                                            
                                        }//:HSTACK
                                        HStack{
                                            Text("충전하기")
                                                .modifier(Heavy(size: 12))
                                                .foregroundColor(.white)
                                                .frame(height: 15)
                                                .padding(.leading, 13)
                                            
                                            Spacer()
                                            
                                        }
                                        
                                    }//:VSTACK
                                })//
                                .frame(width: 100)
                                Spacer()
                                if model.checkCompleted{
                                    Button(action: {
                                        model.reTake()
                                    }, label: {
                                        Text("RESET")
                                            .modifier(Heavy(size: 25))
                                            .foregroundColor(Color.white)
                                            .padding(.trailing, 37 )
                                            .padding(.top, 15)
                                    })
                                }
                            }
                            ShutterButton(isDisabled: model.isDetected, action: {
                                 
                                if UserDefaults.standard.integer(forKey: AppStorageKeys.stars) == 0 {
                                    model.isZeroStarAlert.toggle()
                                }else{
                                    model.isTimerStart.toggle()
                                    debugPrint("타이머 안먹히니")
                                }
                                
                                
                                
                                
                            })
                            .opacity(model.isDetected ? 0.3 : 1)
                            .disabled(model.isDetected)
                          
//                            Button(action:{
//                                //별이 없으면 구매하라고 알림띄움
//                                if stars == 0{
//                                    isZeroStarAlert.toggle()
//                                }else{
//                                    camera.isTimerStart.toggle()
//
//                                }
//                            }  , label: {
//                                Image("Capture")
//                                    .resizable()
//                                    .frame(width: 64, height: 64, alignment: .center)
//                                    .padding(.top, 22)
//                                    .opacity(camera.isTaken ? 0.3 : 1)
//
//
//                            })
//                            .disabled(camera.isDetected)
                            Spacer()
                        }//:ZSTACK
                        
                        ScrollOptionView(index: $optionIndex, isProgressing: $model.isProgressing)
                        
                    }//: VSTACK
                
                }//: ZSTACK
                .frame(height: 150)
                
            }//: VSTACK.
        }//: ZSTACK
        .onAppear(perform: {
            // first checking camerahas got permission...
         
            
            
        })
        
   

       
     
        
        
    }
}

