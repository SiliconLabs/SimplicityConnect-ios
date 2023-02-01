//
//  SettingsView.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 09/12/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    
    let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    
    var body: some View {
        let appInfo = NSLocalizedString("app_info", comment: "")
        NavBarViewWithButtons(title: "Settings") {
            VStack {
                Spacer()
                if #available(iOS 15, *) {
                    Text(LocalizedStringKey(appInfo)).accentColor(.blue)
                }else {
                    LabelView(text: appInfo)
                }
                Spacer()
                Text("App version \(version)").padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
            .background(Color(.sil_background()))
        } trailingInNavBar: {
            EmptyView()
        }
        
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

fileprivate struct LabelView: UIViewRepresentable {
    var text: String

    func makeUIView(context: UIViewRepresentableContext<LabelView>) -> UITextView {
        let label = UITextView()
        label.dataDetectorTypes = .link
        label.isEditable = false
        label.isSelectable = true
        label.font = .systemFont(ofSize: 22)
        label.text = text
        label.tintColor = .blue
        return label
    }

    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<LabelView>) {
        uiView.text = text
    }
}
