//
//  ScrollView.swift
//  focusing
//
//  Created by 고종찬 on 2022/03/27.
//

import SwiftUI

struct ScrollOptionView: View {
    // MARK: - FUNCTION
    func scrollToIndex(_ proxy: ScrollViewProxy, index: Int) {
        withAnimation {
            proxy.scrollTo(index,anchor:.center)
        }
    }
    func scrollToLastIndex(_ proxy: ScrollViewProxy, index: Int) {
        withAnimation {
            proxy.scrollTo(index,anchor:.trailing)
        }
    }
    func scrollToFirstIndex(_ proxy: ScrollViewProxy, index: Int) {
        withAnimation {
            proxy.scrollTo(index,anchor:.leading)
        }
    }
    
    // MARK: - PROPERTY
    @Binding  var index : Int
    @Binding  var isProgressing: Bool
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false){
            ScrollViewReader{value in
                LazyHStack(spacing:30, content: {
                    Button(action: {
                        scrollToIndex(value, index: 0)
                        index = 0
                    }, label: {
                        Text("누가 더 잘생겼는지")
                            .modifier(ExtraBold(size: 15))
                            .foregroundColor(index == 0 ? .white : .gray)
                        
                    })
                    .id(0)
                    
                    Button(action: {
                        scrollToIndex(value, index: 1)
                        index = 1
                    }, label: {
                        Text("누가 더 이쁜지")
                            .modifier(ExtraBold(size: 15))
                            .foregroundColor(index == 1 ? .white : .gray)
                    })
                    .id(1)
                    
                    Button(action: {
                        index = 2
                        scrollToIndex(value, index: 2)
                    }, label: {
                        Text("누가 더 귀여운지")
                            .modifier(ExtraBold(size: 15))
                            .foregroundColor(index == 2 ? .white : .gray)
                        
                    })
                    .id(2)
                    
                    Button(action: {
                        index = 3
                        scrollToIndex(value, index: 3)
                    }, label: {
                        Text("누가 더 돈 많이 벌게 생겼는지")
                            .modifier(ExtraBold(size: 15))
                            .foregroundColor(index == 3 ? .white : .gray)
                        
                    })
                    .id(3)
                    
                    Button(action: {
                        index = 4
                        scrollToIndex(value, index: 4)
                    }, label: {
                        Text("누가 더 말 안 듣게 생겼는지")
                            .modifier(ExtraBold(size: 15))
                            .foregroundColor(index == 4 ? .white : .gray)
                        
                    })
                    .id(4)
                    
                    
                })
                .padding(.horizontal, UIScreen.main.bounds.width/3)
                
            }
        }
        .disabled(isProgressing)
    }
}


