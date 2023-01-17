//
//  MainNavigationView.swift
//  MainNavigationView
//
//  Created by Anastazja Gradowska  on 21/06/2022.
//

import SwiftUI
import CoreData

struct MainNavigationView: View {
    @State var pickedTag = 2
    var body: some View {
        TabView(selection: $pickedTag) {
            DemoTab()
                .tabItem {
                    Image("demoTabIcon")
                    Text("Demo")
                }.tag(0)
            
            TestView()
                .tabItem {
                    Image("testTabIcon")
                    Text("Test")
                }.tag(1)
            
            ScanView()
                .tabItem {
                    Image("scanTabIcon")
                    Text("Scan")
                }.tag(2)
            
            ConfigureView()
                .tabItem {
                    Image( "configureTabIcon")
                    Text("Configure")
                }.tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }.tag(4)
        }
        .padding(.bottom, 2)
        .accentColor(Color.init(.sil_regularBlue()))
        .edgesIgnoringSafeArea(.vertical)
    }
}

struct MainNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        
        MainNavigationView()
    }
}















