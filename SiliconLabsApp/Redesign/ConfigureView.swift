//
//  ConfigureView.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 29/09/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI

struct ConfigureView: View {
    var body: some View {
        PickerTabView(title: "Configure", pickableViews: [AdvertiserView(), GattConfiguratorView()])
    }
}

struct ConfigureView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigureView()
    }
}
