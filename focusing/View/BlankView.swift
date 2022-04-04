//
//  BlankView.swift
//  CoreData&Widget
//
//  Created by 고종찬 on 2022/03/08.
//

import SwiftUI

struct BlankView: View {
    var body: some View {
        VStack{
            Spacer()
        }
        .frame(minWidth: 0, maxWidth: .infinity , minHeight: 0, maxHeight: .infinity, alignment: .center)
        .background(Color.black)
        .opacity(0.7)
        .edgesIgnoringSafeArea(.all)
    }
}

struct BlankView_Previews: PreviewProvider {
    static var previews: some View {
        BlankView()
    }
}
