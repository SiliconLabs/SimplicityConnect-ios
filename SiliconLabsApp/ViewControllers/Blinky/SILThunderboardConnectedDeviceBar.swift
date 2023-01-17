//
//  SILThunderboardConnectedDeviceBar.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 28/10/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

protocol SILThunderboardConnectedDeviceBar: class {
    var connectedDeviceView: ConnectedDeviceBarView? { get set }
    var connectedDeviceBarHeight: CGFloat { get set }
    func addConnectedDeviceBar(bottomNotchHeight value: CGFloat)
    func updateDeviceInfo(_ name: String, power: PowerSource, firmware: String?)
}

extension SILThunderboardConnectedDeviceBar where Self: UIViewController {

    func updateDeviceInfo(_ name: String, power: PowerSource, firmware: String?) {
        if let connectedDeviceView = self.connectedDeviceView {
            DispatchQueue.main.async {
                connectedDeviceView.deviceNameLabel.text = name
                connectedDeviceView.powerType = power
                if let firmware = firmware {
                    connectedDeviceView.firmwareVersionLabel.tb_setText(firmware, style: StyleText.subtitle2)
                }
                else {
                    connectedDeviceView.firmwareVersionLabel.tb_setText(String.tb_placeholderText(), style: StyleText.subtitle2)
                }
            }
        }
    }


    func setupConnectedDeviceBar() {
        if let connectedDeviceView = UINib(nibName: "ConnectedDeviceBarView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? ConnectedDeviceBarView {
            connectedDeviceView.backgroundColor = StyleColor.white
            connectedDeviceView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(connectedDeviceView)
            
            NSLayoutConstraint.activate([
                connectedDeviceView.heightAnchor.constraint(equalToConstant: connectedDeviceBarHeight),
                connectedDeviceView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                connectedDeviceView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                connectedDeviceView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            ])
            
            connectedDeviceView.addShadow()
            self.connectedDeviceView = connectedDeviceView 
        }
    }

    func addConnectedDeviceBar(bottomNotchHeight: CGFloat) {
        connectedDeviceBarHeight += bottomNotchHeight
        self.setupConnectedDeviceBar()
    }
}

