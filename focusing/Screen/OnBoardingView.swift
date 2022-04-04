//
//  OnBoardingView.swift
//  focusing
//
//  Created by 고종찬 on 2022/03/27.
//

import SwiftUI

struct OnBoardingView: View {
    
    
  
    var body: some View {
        ZStack{
            
            Image("logo")
                .resizable()
                .frame(width: 194, height: 44, alignment: .center)
        }.ignoresSafeArea(.all)
       
    

    }
}

struct OnBoardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnBoardingView()
    }
}
