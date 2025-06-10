//
//  SettingsView.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 09/12/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI
import DeviceGuru
import CoreBluetooth
import AVFoundation
import Foundation

var globalCounter: Bool = true

struct SettingsView: View {
    
    let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    @State private var showView = false
    
    let bleCapabilities = BLECapabilities()
    
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
            .sheet(isPresented: $showView) {
                DetailView(showSheet: $showView)
            }
        } trailingInNavBar: {
            Button(action: {
                showView.toggle()
            }) {
                Image(systemName: "info.circle").imageScale(.large)
            }
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
    
    func getBoardInfo() -> String {
        // iOS does not provide direct access to the board info, so we return a placeholder value
        return "N/A"
    }
    
    func getProductInfo() -> String {
        // iOS does not provide direct access to the product info, so we return a placeholder value
        return "N/A"
    }
}


// MARK: Device Information

class GlobalState: ObservableObject {
    static let shared = GlobalState()
    @Published var isBLESupported: Bool = false
    @Published var isPeripheralModeSupported: Bool = false
//    @Published var isNativeHIDsupported: Bool = false
}

struct TwoColumnRow: View {
    var leftText: String
    var rightText: String
    
    var body: some View {
        HStack {
            Text(leftText)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(rightText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct DetailView: View {
    @Binding var showSheet: Bool
    let device = UIDevice.current
    @ObservedObject var globalState = GlobalState.shared
    
    var body: some View {
        NavigationView {
            VStack (alignment: .leading) {
                
                let deviceGuru = DeviceGuruImplementation()
                var modelName: String? { try? deviceGuru.hardwareDescription() }
                
                Text("Headware:").font(.headline).padding()
                VStack(spacing: 0) {
                    TwoColumnRow(leftText: "Device Name:", rightText: "\(device.name)")
                    TwoColumnRow(leftText: "IOS Version:", rightText: "\(device.systemVersion)")
                    TwoColumnRow(leftText: "Manufacturer:", rightText: "Apple")
                    TwoColumnRow(leftText: "Model:", rightText: "\(modelName ?? "N/A")")
                    //TwoColumnRow(leftText: "Build Version:", rightText: "\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A")")
                }.padding(.leading)
                
                Text("")
                Text("Bluetooth Low Energy:").font(.headline).padding()
                VStack(spacing: 0) {
                    TwoColumnRow(leftText: "BLE Support Status:", rightText: "\(globalState.isBLESupported ? "YES" : "Not Supported")")
                    TwoColumnRow(leftText: "Peripheral mode supported:", rightText: "\(globalState.isPeripheralModeSupported ? "YES" : "Not Supported")")

                }.padding(.leading)
                
                Text("")
                Text("Screen:").font(.headline).padding()
                
                let resolution = getScreenResolution()
                let formattedWidth = String(format: "%.1f", resolution.width)
                let formattedHeight = String(format: "%.1f", resolution.height)
                
                let screenDimensions = getScreenDimensionsInDIP()
                let screenDimensionsWidth = String(format: "%.1f", screenDimensions.width)
                let screenDimensionsHeight = String(format: "%.1f", screenDimensions.height)
                
                let wideColorGamutSupported = isWideColorGamutSupported()
                let hdrSupported = isHDRSupported()
                let aspectRatio = getAspectRatio()
                
                VStack(spacing: 0) {
                    TwoColumnRow(leftText: "Dimensions(px):", rightText: " \(formattedWidth) x \(formattedHeight)")
                    TwoColumnRow(leftText: "Dimensions(dpi):", rightText: "\(screenDimensionsWidth) x \(screenDimensionsHeight)")
                    TwoColumnRow(leftText: "Wide color gamut:", rightText: "\(wideColorGamutSupported ? "Supported" : "Not supported")")
                    TwoColumnRow(leftText: "High Dynamic Range (HDR):", rightText: "\(hdrSupported ? "Supported" : "Not supported")")
                    TwoColumnRow(leftText: "Aspect ratio:", rightText: "\(aspectRatio)")
                }.padding(.leading)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationBarTitle("System Information", displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                showSheet = false
            }) {
                Text("Back")
                    .font(.headline)
                    .foregroundColor(.white)
            })
        }
    }
    
    // Private metholds
    private func getScreenResolution() -> CGSize {
        let screenSize = UIScreen.main.bounds.size
        let screenScale = UIScreen.main.scale
        let screenResolution = CGSize(width: screenSize.width * screenScale, height: screenSize.height * screenScale)
        return screenResolution
    }
    
    private func getScreenDimensionsInDIP() -> CGSize {
        let screenSize = UIScreen.main.bounds.size
        return screenSize
    }
    
    private func isWideColorGamutSupported() -> Bool {
        let screen = UIScreen.main
        return screen.traitCollection.displayGamut == .P3
    }
    
    private func isHDRSupported() -> Bool {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return false
        }
        return captureDevice.activeFormat.isVideoHDRSupported
    }
    
    private func getAspectRatio() -> String {
        let screenSize = UIScreen.main.bounds.size
        let aspectRatio = screenSize.width / screenSize.height
        return String(format: "%.2f:1", aspectRatio)
    }
}

class BLECapabilities: NSObject, CBCentralManagerDelegate, CBPeripheralManagerDelegate {
    
    @ObservedObject var globalState = GlobalState.shared
        
    var centralManager: CBCentralManager!
    var peripheralManager: CBPeripheralManager!
    var scanedPeripherals: [CBPeripheral] = []
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        //
    }
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
            
            globalState.isBLESupported = true
            
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            
            // Check if BLE is supported
            if #available(iOS 10.0, *) {
                if CBCentralManager.supports(.extendedScanAndConnect) {
                    print("Extended Scan and Connect supported")
                }
            }
            // Check if Peripheral mode is supported
            if CBPeripheralManager.authorization == .allowedAlways {
                print("Peripheral mode supported")
            }
            
        case .poweredOff:
            globalState.isBLESupported = false
        case .resetting:
            globalState.isBLESupported = false
        case .unauthorized:
            globalState.isBLESupported = false
        case .unsupported:
            globalState.isBLESupported = false
        case .unknown:
            globalState.isBLESupported = false
        @unknown default:
            globalState.isBLESupported = false
        }
    }
    
    // Function to check if a peripheral is already in the array
    func isPeripheralAvailable(_ peripheral: CBPeripheral) -> Bool {
        return scanedPeripherals.contains { $0.identifier == peripheral.identifier }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        scanedPeripherals.append(peripheral)
        // Check for manufacturer-specific data
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            if manufacturerData.count >= 2 {
                let companyCode = manufacturerData.prefix(2).withUnsafeBytes { $0.load(as: UInt16.self) }

                if isPeripheralAvailable(peripheral) {
                    globalState.isPeripheralModeSupported = true
                } else {
                    globalState.isPeripheralModeSupported = false
                }
            }
        }
    }
}
