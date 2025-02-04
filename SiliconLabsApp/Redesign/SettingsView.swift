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
            
            ScrollView {
                VStack {
                    Spacer()
                    CardViewWithPicker()
                    Spacer()
                    Section {
                        if #available(iOS 15, *) {
                            Text(LocalizedStringKey(appInfo)).accentColor(.blue)
                        }else {
                            LabelView(text: appInfo)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    Text("App version \(version)").padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
                .background(Color(.sil_background()))

            }
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

struct CardViewWithPicker: View {

    var timeOutValue = ["15 seconds", "1 minute", "2 minutes", " 5 minutes", "10 minutes", "No timeout"]
    @State private var selectedOption: String = UserDefaults.standard.string(forKey: "SelectedOption") ?? "1 minute"

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            Text("Select Scaning Timeout:")
                .font(.subheadline)
                .foregroundColor(Color.black)
            
            Spacer()

            Picker("Options", selection: $selectedOption) {
                ForEach(timeOutValue, id: \.self) { option in
                    Text(option).tag(option)
                        .foregroundColor(Color.black)
                }
            }
            .tint(.blue)
            .pickerStyle(MenuPickerStyle())
            .onChange(of: selectedOption) { newValue in
                saveToUserDefaults(newValue) // Save the selected value to UserDefaults
            }
            
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(.white))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding()
        
    }

    // Function to save to UserDefaults
    private func saveToUserDefaults(_ value: String) {
        UserDefaults.standard.set(value, forKey: "SelectedOption")
    }
}

