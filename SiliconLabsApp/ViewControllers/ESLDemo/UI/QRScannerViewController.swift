//
//  QRScannerViewController.swift
//  BlueGecko
//
//  Created by Anastazja Gradowska on 06/02/2023.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class QRScannerViewController: UIViewController {
    @IBOutlet var messageLabel: UILabel!
    
    private var captureSession: AVCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var qrCodeFrameView: UIView?
    weak var delegate: QRMetadataDelegate?
    var viewModel: QRScannerViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            debugPrint("Error when creating capture device input \(error.localizedDescription)")
            return
        }
        
        addVideoInputIfPossible(videoInput: videoInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        addMetadataOutputIfPossible(metadataOutput: metadataOutput)
        
        setupVideoPreviewLayer()
        view.bringSubviewToFront(messageLabel)
        setupQrCodeFrameView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (captureSession.isRunning == false) {
            captureSession.startRunning()
        }
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    private func addVideoInputIfPossible(videoInput: AVCaptureDeviceInput) {
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
        }
    }
    
    private func addMetadataOutputIfPossible(metadataOutput: AVCaptureMetadataOutput) {
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
        }
    }
    
    private func setupVideoPreviewLayer() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
    }
    
    private func setupQrCodeFrameView() {
        qrCodeFrameView = UIView()
            
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.yellow.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubviewToFront(qrCodeFrameView)
        }
    }
    
    private func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            messageLabel.text = "No QR code is detected"
            return
        }

        let metadataObj = metadataObjects.first as! AVMetadataMachineReadableCodeObject

        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            if let barCodeObject = videoPreviewLayer.transformedMetadataObject(for: metadataObj) {
                qrCodeFrameView?.frame = barCodeObject.bounds
            }

            if let metadata = metadataObj.stringValue {
                let qrData = viewModel.readQR(metadata: metadata)
                delegate?.setQRData(qrData)
                navigationController?.popViewController(animated: true)
                dismiss(animated: true, completion: nil)
            }
        }
    }
}

