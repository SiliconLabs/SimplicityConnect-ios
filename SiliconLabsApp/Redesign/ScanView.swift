//
//  ScanView.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 23/06/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI

struct ScanView: View {
    var body: some View {
        PickerTabView(title: "BLE Devices", pickableViews: [ScannerView(), RSSIGraphView(), ActiveConnectionsView()])
    }
}

struct ScanView_Previews: PreviewProvider {
    static var previews: some View {
        ScanView()
    }
}

extension SILBrowserConnectionsViewModel : ObservableObject {
    @objc func notifyObjectChanged() {
        self.objectWillChange.send()
    }
}

