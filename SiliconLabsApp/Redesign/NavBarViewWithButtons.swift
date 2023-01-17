//
//  NavBarViewWithButtons.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 23/06/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI

struct NavBarViewWithButtons<Content : View, Buttons : View>: View {
    let title : String
    let innerView: Content
    let trailingInNavBar : Buttons
    
    init(title : String, @ViewBuilder innerView: () -> Content, @ViewBuilder trailingInNavBar : () -> Buttons ){
        self.title = title
        self.innerView = innerView()
        self.trailingInNavBar = trailingInNavBar()
    }
    
    var body: some View {
        NavigationView {
            innerView
                .navigationBarTitle(Text(""), displayMode: .inline)
                .navigationBarItems(leading: Text(title).font(.system(size: 21)).foregroundColor(.white) ,trailing:
                    trailingInNavBar
                )
        }.navigationViewStyle(.stack)
            .accentColor(.white)
    }
}

struct NavBarViewWithButtons_Previews: PreviewProvider {
    static var previews: some View {
        NavBarViewWithButtons(title: "", innerView: {
        }, trailingInNavBar: {HStack {
            Button(action: {
                print("Icon pressed...")
            }) {
                Image(systemName: "person.crop.circle").imageScale(.large)
            }
        
            Button(action: {
                print("Icon pressed...")
            }) {
                Image(systemName: "person.crop.circle").imageScale(.large)
            }
        }})
    }
}
