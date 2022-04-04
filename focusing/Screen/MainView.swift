//
//  MainView.swift
//  focusing
//
//  Created by 고종찬 on 2022/03/27.
//

import SwiftUI
import StoreKit
import Vision

struct MainView: View {
    
    
    //MARK: - FUNCTION
    
    
    
    
    
    
    
    //MARK: - PROPERTY
    @StateObject var camera = CameraModel()
    @StateObject var storeManager = StoreManager()
    @State private var timeRemaining = 3
    @State var optionIndex = 0
    @State private var isTexting = false
    @State private var convertedImage:UIImage?
    
    //별이 없는 경우
    @State private var isZeroStarAlert = false
    @State private var moveToShop = false
    
    
    let timer = Timer.publish(every: 1.0, on: .current, in: .common).autoconnect()
    
    let productIDs = [ "star10","star20","star50"]
    @AppStorage("stars") var stars: Int = 7
    
    var body: some View {
        
        ZStack{
            
            if camera.isDetected{
                
                Image(uiImage: camera.detectedImage!)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                
                
                
            }
                CameraPreview(camera: camera)
//                DetectedCameraPreview()
                    .edgesIgnoringSafeArea(.all)
                //                .edgesIgnoringSafeArea(.top)
                    .opacity(camera.isDetected ? 0 : 1)
                    .onDisappear(perform: {
                        debugPrint("카메라 사라짐")
                        camera.session.stopRunning()
                        camera.trackingRequests?.removeAll()
                        camera.detectionRequests?.removeAll()
                    })
                    .onAppear(perform:{
                        debugPrint("카메라 나타남")
                      
                        
                    })
            
            //                .opacity(1)
            
            
            
            
            if camera.isProgressing{
                
                ProgressView()
                    .scaleEffect(3)
                    .frame(width: 80, height: 80)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("tangerine")))
                
                
            }
            
            
            
            
            
            
            // MARK: - BODY
            VStack{
                Spacer()
                ZStack{
                    
                    if camera.isTimerStart {
                        
                            Text("\(timeRemaining)")
                                .modifier(ExtraBold(size: 150))
                                .foregroundColor(Color("tangerine"))
                                .frame(width: 100, height: 188, alignment: .center)
                                .opacity(timeRemaining == 0 ? 0 : 1)
                                .opacity(timeRemaining == 3 ? 0 : 1)
                        
                        
                    }
                    
                    
                    if camera.isTaken{
                        HStack{
                            Button(action: {
                                camera.reTake()
                                //초기화
                                
                            }, label: {
                                Image("back")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                            })
                            .padding(.leading, 57)
                            Spacer()
                            Button(action: {
                                camera.requestImage(index: optionIndex)
                            }, label: {
                                Image("go")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                            })
                            .padding(.trailing, 57)
                        }//:HSTACK
                        
                        
                        
                    }
                    
                    
                    
                    
                    
                    if camera.errorDetected{
                        
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
                                NavigationLink(isActive: $moveToShop,
                                               
                                               destination: {
                                    InAppPurchaseView(camera: camera, storeManager: storeManager)
                                        .onAppear(perform: {
                                            storeManager.getProducts(productIDs: productIDs)
                                            SKPaymentQueue.default().add(storeManager)
                                           
                                        })
                                    
                                }, label: {
                                    VStack{
                                        
                                        HStack{
                                            Image("Star")
                                                .resizable()
                                                .frame(width: 30, height: 30)
                                                .padding(.leading, 13)
                                            Text("\(stars)")
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
                                if camera.checkCompleted{
                                    Button(action: {
                                        camera.reTake()
                                    }, label: {
                                        Text("RESET")
                                            .modifier(Heavy(size: 25))
                                            .foregroundColor(Color.white)
                                            .padding(.trailing, 37 )
                                            .padding(.top, 15)
                                    })
                                }
                            }
                            
                            Button(action:{
                                //별이 없으면 구매하라고 알림띄움
                                if stars == 0{
                                    isZeroStarAlert.toggle()
                                }else{
                                    camera.isTimerStart.toggle()
                                    
                                }
                            }  , label: {
                                Image("Capture")
                                    .resizable()
                                    .frame(width: 64, height: 64, alignment: .center)
                                    .padding(.top, 22)
                                    .opacity(camera.isTaken ? 0.3 : 1)
                                   
                                
                            })
                            .disabled(camera.isDetected)
                            Spacer()
                        }//:ZSTACK
                        
                        ScrollOptionView(index: $optionIndex, isProgressing: $camera.isProgressing)
                        
                    }//: VSTACK
                }//: ZSTACK
                .frame(height: 150)
                
            }//: VSTACK.
        }//: ZSTACK
        .onAppear(perform: {
         
            camera.Check()
            
            
        })
        .onDisappear(perform: {
//            camera.detectionRequests?.removeAll()
//            camera.trackingRequests?.removeAll()
//            camera.session.stopRunning()
            
        })
        .alert(isPresented: $camera.alert) {
            Alert(title: Text("Focusing의 기능을 사용하기 위해 카메라 사용을 요청합니다."))
        }
        .alert(isPresented: $isZeroStarAlert){
          
            Alert(title: Text("별이 부족합니다."), message: Text("상점으로 이동하시겠습니까?"), primaryButton: .default(Text("취소").foregroundColor(Color.black)), secondaryButton: .default(Text("확인").foregroundColor(Color.black), action: {
                moveToShop.toggle()
            }))
        }
        .onReceive(timer) { _ in
            if camera.isTimerStart{
                if timeRemaining > 0 {
                    timeRemaining -= 1
                
                }else if timeRemaining == 0 {
                    camera.takePic()
                    camera.cameraTimerIsZero = true
                    timeRemaining = 3
                    camera.isTimerStart.toggle()
                    
                }
                
            }
        }
        
        
    }
}

