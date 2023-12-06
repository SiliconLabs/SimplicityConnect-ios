//
//  PickerTabView.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 23/06/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI
import Combine
import Introspect

struct PickerTabView: View {
    @State var pickerTagChosen = 0
    @ObservedObject var floatingButtonSetting : FloatingButtonSettings = FloatingButtonSettings()
    @ObservedObject var connectionsVM = SILBrowserConnectionsViewModel.sharedInstance()
    
    let title : String
    let pickableViews : [any PickerTabSubview]
    
    var chosenSubview : any PickerTabSubview {
        pickableViews[pickerTagChosen]
    }
    var chosenView : AnyView {
        AnyView(erasing: chosenSubview)
    }
    
    var body: some View {
        NavBarViewWithButtons(title: title, innerView: {
            ViewWithFloatingButton(buttonTitle: floatingButtonSetting.text, buttonPresented: floatingButtonSetting.isPresented, buttonAction:
                                    chosenSubview.floatingButtonAction, buttonColor: floatingButtonSetting.color
            , mainBody: {
                VStack {
                    Picker("Picker", selection: $pickerTagChosen) {
                        ForEach(0..<pickableViews.count, id: \.self) { i in
                            Text(pickableViews[i].title.uppercased()).tag(i)
                        }
                    }
                    .padding()
                    .pickerStyle(SegmentedPickerStyle())
                    .onReceive(Just(pickerTagChosen)) { x in
                        chosenSubview.setFloatingButton(settings: floatingButtonSetting)
                    }
                    
                    chosenView
                }.background(Color(.sil_regularBlue()))
            })
        }, trailingInNavBar: {
            HStack {
                ForEach(chosenSubview.buttons) { button in
                    Button(action: {
                        button.action()
                    }) {
                        button.image.foregroundColor(.white)
                    }
                }
            }
        }).introspectTabBarController { uiTabBarController in
            uiTabBarController.setTabBarVisible(visible: true,
                                                animated: true,
                                                controllerHeight: floatingButtonSetting.controllerHeight)
        }
        // Keeping commented code for future referance for tabbar hide.
//        { uiTabBarController in
//            uiTabBarController.setTabBarVisible(visible: floatingButtonSetting.isPresented,
//                                                animated: true,
//                                                controllerHeight: floatingButtonSetting.controllerHeight)
//        }
    }
}

struct PickerTabView_Previews: PreviewProvider {
    static var previews: some View {
        PickerTabView(title: "Configure", pickableViews: [AdvertiserView(), GattConfiguratorView()])
    }
}

protocol PickerTabSubview : View {
    func floatingButtonAction()
    func setFloatingButton(settings: FloatingButtonSettings)
    
    var buttons: [NavBarButton] { get }
    var title : String { get }
}

@objc public class FloatingButtonSettings : NSObject, ObservableObject {
    var text: String = ""
    var isPresented: Bool = false
    var color : UIColor = .sil_regularBlue()
    @IBOutlet weak var controllerHeight: NSLayoutConstraint?
    
    @objc func setButtonText(_ text: String) {
        if text != self.text {
            self.text = text
            self.objectWillChange.send()
        }
    }
    
    @objc func setPresented(_ presented: Bool) {
        if presented != self.isPresented {
            self.isPresented = presented
            self.objectWillChange.send()
        }
    }
    
    @objc func setColor(_ color: UIColor) {
        if color != self.color {
            self.color = color
            self.objectWillChange.send()
        }
    }
}

public struct NavBarButton : Identifiable {
    public var id : String
    let image : Image
    let action : () -> ()
}
