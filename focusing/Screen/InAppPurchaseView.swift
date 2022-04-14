//
//  InAppPurchaseView.swift
//  focusing
//
//  Created by 고종찬 on 2022/03/27.
//

import SwiftUI
import StoreKit

struct InAppPurchaseView: View {
    
    
    //MARK: - View
    var buttonBack : some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image("BackButton") // set image here
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
                
            }
        }
    }
    //MARK: - PROPERTY
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var index = 0
    
    @StateObject var storeManager: StoreManager
    
    var conditions = """
    - 사용자가 앱서비스, 데이터 캐시 등을 삭제하게 되면 결제한 유료 상품에 대한 데이터가 사라지며 이에 대한 복원 및 환불이 불가능하니 주의하시기 바랍니다.
    
    - 결제는 인앱결제(앱스토어, 플레이스토어)를 통해 이루어지며 결제 및 환불 과정에 대한 정보는 당사에서 관리하는 것이 아닌 스토어에서 보관 및 처리되며 각사의 서비스 약관에 따릅니다.
    
    - 각 스토어의 약관에 따라 구매자가 결제한 스토어에 직접 환불을 요청해야할 수 있으며, 각 스토어의 환불 정책에 따라 환불이 거부될 수 있습니다. 또한 회원이 구매한 상품을 이미 사용한 경우에는 환불이 불가능합니다.
    
    - 미성년자의 경우 충전을 할 시 법정대리인이 결제에 대해 동의한 것으로 간주됩니다.
    """
    
    
    
    //MARK: - FUNCTION
    
    
    
    var body: some View {
        NavigationView{
            ScrollView(showsIndicators: false){
                
                ZStack{
                    if !storeManager.isLoaded{
                        ProgressView()
                            .scaleEffect(3)
                            .frame(width: 80, height: 80)
                            .progressViewStyle(CircularProgressViewStyle(tint: Color("tangerine")))
                    }
                    VStack(alignment: .leading,spacing: 10){
                        HStack{
                            Image("logo")
                                .resizable()
                                .frame(width: 173, height: 40)
                            //                            .padding(.leading, 26)
                            
                        }//:HSTACK
                        Text("친구들과의 관상 대결, \n안면인식 콘텐츠")
                            .modifier(Medium(size:17))
                        //                        .padding(.leading, 26)
                            .padding(.bottom,5)
                        
                        Text("포커씽은 한국인의 외모를 다양한 관상 주제에 맞춰 딥러닝하고 판독합니다. \n친구들과 엔터테인먼트 콘텐츠로써 함계 즐겨보세요!")
                            .modifier(Medium(size:10))
                            .foregroundColor(Color("brownGrey"))
                        //                        .padding(.leading, 26)
                            .frame(height: 30)
                        
                            .padding(.bottom, 43)
                         
                        Group{
                            Button(action: {
                                withAnimation{
                                    index = 0
                                    
                                    
                                }
                            }, label: {
                                Image(index == 0 ? "InAppBox": "InAppBoxUnselected")
                                    .resizable()
                                    .frame(width:UIScreen.main.bounds.width - 52  ,height: 56)
                                    .overlay(
                                        HStack{
                                            Image(index == 0 ? "CheckYellow":"CheckGrey")
                                                .resizable()
                                                .frame(width: 20, height: 20, alignment: .center)
                                            Image("Star")
                                                .resizable()
                                                .frame(width: 30, height: 30, alignment: .center)
                                            Text("10개")
                                                .modifier(SemiBold(size: 20))
                                            Spacer()
                                            Text("1,200KRW")
                                                .modifier(SemiBold(size: 20))
                                        }
                                            .padding()
                                        
                                    )
                                
                            })
                            Button(action: {
                                withAnimation{
                                    index = 1
                                    
                                }
                            }, label: {
                                Image(index == 1 ? "InAppBox": "InAppBoxUnselected")
                                    .resizable()
                                    .frame(width:UIScreen.main.bounds.width - 52  ,height: 56)
                                    .overlay(
                                        HStack{
                                            Image(index == 1 ? "CheckYellow":"CheckGrey")
                                                .resizable()
                                                .frame(width: 20, height: 20, alignment: .center)
                                            Image("Star")
                                                .resizable()
                                                .frame(width: 30, height: 30, alignment: .center)
                                            Text("20개")
                                                .modifier(SemiBold(size: 20))
                                            Spacer()
                                            Text("2,200KRW")
                                                .modifier(SemiBold(size: 20))
                                        }
                                            .padding()
                                        
                                    )
                                
                            })
                            Button(action: {
                                withAnimation{
                                    index = 2
                                    
                                }
                            }, label: {
                                Image(index == 2 ? "InAppBox": "InAppBoxUnselected")
                                    .resizable()
                                    .frame(width:UIScreen.main.bounds.width - 52  ,height: 56)
                                    .overlay(
                                        HStack{
                                            Image(index == 2 ? "CheckYellow":"CheckGrey")
                                                .resizable()
                                                .frame(width: 20, height: 20, alignment: .center)
                                            Image("Star")
                                                .resizable()
                                                .frame(width: 30, height: 30, alignment: .center)
                                            Text("50개")
                                                .modifier(SemiBold(size: 20))
                                            Spacer()
                                            Text("4,900KRW")
                                                .modifier(SemiBold(size: 20))
                                        }
                                            .padding()
                                        
                                    )
                                
                            })
                            
                        }//:GROUP
                        .foregroundColor(.black)
                        .frame(width:UIScreen.main.bounds.width - 52  ,height: 56)
                        
                        Spacer(minLength: 30)
                        
                        HStack{
                            Spacer()
                            Button(action: {
                                storeManager.purchaseProduct(product: storeManager.myProducts[index])
                                
                            }, label: {
                                Image("RechargeCapsule")
                                    .resizable()
                                    .frame(width:UIScreen.main.bounds.width - 134  ,height: 56)
                                    .overlay(
                                        Text("충전하기")
                                            .modifier(SemiBold(size: 18))
                                            .foregroundColor(.white)
                                        
                                    )
                                    
                                
                            })
                            .disabled(!storeManager.isLoaded)
//                            .frame(width:UIScreen.main.bounds.width - 134  ,height: 56, alignment:.center)
                            Spacer(minLength: 20)
                            
                        }//:HSTACK
                        HStack{
                            Spacer()
                            NavigationLink(destination: TermsOfUseView(), label: {
                                Text("서비스 이용약관")
                                    .modifier(SemiBold(size: 10))
                                
                            })
                            Divider()
                            NavigationLink(destination: PrivacyPolicyView(), label: {
                                Text("개인정보 처리방침")
                                    .modifier(SemiBold(size: 10))
                                
                            })
                            Divider()
                            NavigationLink(destination: QAView(), label: {
                                Text("문의하기")
                                    .modifier(SemiBold(size: 10))
                            })
                            Spacer()
                        }//:HSTACK
                        
                        .foregroundColor(Color("brownGrey"))
                        .frame(height: 13, alignment: .center)
                        
                        Spacer(minLength: 47)
                        
                        Text(conditions)
                            .modifier(Medium(size: 8))
                            .foregroundColor(Color("brownGrey"))
                            .frame(width: UIScreen.main.bounds.width - 44, alignment: .center)
                        
                    }//:VSTACK
                    
                    
                    .frame(width: UIScreen.main.bounds.width - 52 , alignment: .leading)
                    //                .edgesIgnoringSafeArea(.bottom)
                    .offset(y: -20)
                    
                }//:ZSTACK
                .onAppear{
                  
                   
                }
                .onDisappear(perform: {
                    
                })
                
                
                
                //            .padding()
                .navigationBarBackButtonHidden(true)
                .navigationBarItems(leading: buttonBack)
                .onChange(of: storeManager.isPurchased, perform: {_ in
                    self.presentationMode.wrappedValue.dismiss()
                    
                })
            }
            
        }
        
        .navigationBarHidden(true)
    }
}

//struct InAppPurchaseView_Previews: PreviewProvider {
//    static var previews: some View {
//        InAppPurchaseView()
//    }
//}
