//
//  TermsOfUseView.swift
//  Weggle
//
//  Created by Apple on 2021/05/04.
//

import SwiftUI

struct QAView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var buttonBack : some View { Button(action: {
        self.presentationMode.wrappedValue.dismiss()
    }) {
        HStack {
            Image("BackButton") // set image here
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white)
            
        }
    }
    }
    
    var askingText = """

 """
    
    var body: some View {
        
        
        ScrollView(/*@START_MENU_TOKEN@*/.vertical/*@END_MENU_TOKEN@*/, showsIndicators: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/, content: {
            HStack{
                Text("문의하기")
                    .modifier(Medium(size: 20))
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                
            }
            Spacer(minLength: 38)
            HStack{
                Text("focusinginc@gmail.com \n오류 및 문의 사항은 위 메일로 연락주시기 바랍니다.")
                    .modifier(Medium(size: 12))
                    .lineSpacing(1.6)
                    .foregroundColor(Color.black)
                    .multilineTextAlignment(.leading)
                Spacer()
                
            }
        })
        .padding(24)
        .offset(y: -20.0/*@END_MENU_TOKEN@*/)
        //                .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: buttonBack)
        
    }
}

