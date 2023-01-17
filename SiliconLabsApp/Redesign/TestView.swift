//
//  TestView.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 23/06/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI

struct TestView: View {
    var body: some View {
        PickerTabView(title: "Test", pickableViews: [IOPView()])
    }
}

struct IOPTestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}
