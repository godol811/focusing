//
//  AgreeView.swift
//  focusingUIUX
//
//  Created by 고종찬 on 2022/03/14.
//

import SwiftUI

struct AgreeView: View {
    
    //MARK: - PROPERTY
    @AppStorage("agreed") var isAgreed: Bool = false
    
    
    
    var body: some View {
        
            VStack{
                HStack{
                    Button(action: {
                        withAnimation(){
                            isAgreed = true
                            
                        }
                    }, label: {
                        Image(isAgreed ?   "CheckYellow" : "CheckGrey")
                            .resizable()
                            .frame(width: 20, height: 20)
                    })
                    
                    
                    Text("동의하기")
                        .modifier(Medium(size: 20))
                }//: HSTACK
                .frame(width: UIScreen.main.bounds.width, height: 85.8)
                Divider()
                    .offset(y: -10)
                
                
                HStack{
                    NavigationLink(destination: TermsOfUseView(), label: {
                        Text("서비스 이용약관(필수)")
                            .modifier(Medium(size: 12))
                            .frame(height: 15, alignment: .center)
                            .padding(.trailing, 40)
                        
                    })
                    
                    Divider()
                        .frame(height: 36, alignment: .center)
                    
                    NavigationLink(destination: PrivacyPolicyView(), label: {
                        Text("개인정보 처리방침(필수)")
                            .modifier(Medium(size: 12))
                            .frame(height: 15, alignment: .center)
                           .padding(.leading, 40)
                            
                        
                    })
                    
                    
                }//: HSTACK
                .foregroundColor(Color("brownGrey"))
                .frame(width: UIScreen.main.bounds.width,height: 63.8)
                .offset(y: -10)
                
                
            }//: VSTACK
            .frame(width: UIScreen.main.bounds.width, height: 150)
            
        
    }
}

struct AgreeView_Previews: PreviewProvider {
    static var previews: some View {
        AgreeView()
            .previewLayout(.sizeThatFits)
            
            
    }
}
