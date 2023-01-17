//
//  ViewWithFloatingButton.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 30/06/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI

struct ViewWithFloatingButton<MainContent : View>: View {
    let buttonTitle : String
    let buttonPresented : Bool
    let buttonAction : () -> ()
    let buttonColor : UIColor
    @ViewBuilder let mainBody : () -> MainContent
    
    var body: some View {
        ZStack {
            mainBody()
            if buttonPresented {
                ButtonView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding()
            }
        }
    }
    
    @ViewBuilder func ButtonView() -> some View {
        Button(action: buttonAction, label: {
            Text(buttonTitle).font(.headline).foregroundColor(Color.white).padding(20)
                .background(RoundedRectangle(cornerRadius: 20.0).foregroundColor(Color(buttonColor)))
                
        })
    }
    
}

struct ViewWithFloatingButton_Previews: PreviewProvider {
    static var previews: some View {
        ViewWithFloatingButton(buttonTitle: "Create new", buttonPresented: true, buttonAction: {
            print("Akcja")
        }, buttonColor: .sil_regularBlue(), mainBody: {
            DemoView()
        })
    }
}
