//
//  DemoTab.swift
//  BlueGecko
//
//  Created by Hubert Drogosz on 04/10/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import SwiftUI

struct DemoTab: View {
    var body: some View {
        NavBarViewWithButtons(title: "Demo") {
            DemoView()
        } trailingInNavBar: {
            EmptyView()
        }

    }
}

struct DemoTab_Previews: PreviewProvider {
    static var previews: some View {
        DemoTab()
    }
}
