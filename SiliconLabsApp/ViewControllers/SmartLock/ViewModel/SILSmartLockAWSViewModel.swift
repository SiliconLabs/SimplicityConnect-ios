//
//  SILSmartLockAWSViewModel.swift
//  SiliconLabsApp
//
//  Created by Mantosh Kumar on 06/07/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import Foundation
import AWSCore
import AWSIoT

protocol SILSmartLockAWSViewModelProtocol: NSObject {
    func notifySmartLockConnectionStatus(isConeected: Bool, status:AWSIoTMQTTStatus, msg: String)
}

class SILSmartLockAWSViewModel: NSObject {
    var SILSmartLockAWSViewModelDelegate: SILSmartLockAWSViewModelProtocol?
    
    var networkSlowTimer: Timer?
    
    @objc var connected = false
    @objc var iotManager: AWSIoTManager!
    @objc var iot: AWSIoT!
    @objc var iotDataManager: AWSIoTDataManager!
    
    var selectedCertificate: String? = ""
    var selectedCertificatePassword: String = ""
    var selectedAWSEndPoint: String = ""
    
    init(SILSmartLockAWSViewModelDelegate: SILSmartLockAWSViewModelProtocol? = nil) {
        super.init()
        self.SILSmartLockAWSViewModelDelegate = SILSmartLockAWSViewModelDelegate as? any SILSmartLockAWSViewModelProtocol
        connected = false
    }
    
    // MARK: AWS IoT initial setup
    
    func initialSetupOfAWSIOT() {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:AWS_REGION, identityPoolId: IDENTITY_POOL_ID)
        initializeControlPlane(credentialsProvider: credentialsProvider)
        initializeDataPlane(credentialsProvider: credentialsProvider)
    }
    
    func initializeControlPlane(credentialsProvider: AWSCredentialsProvider) {
        //Initialize control plane
        // Initialize the Amazon Cognito credentials provider
        let controlPlaneServiceConfiguration = AWSServiceConfiguration(region:AWS_REGION, credentialsProvider:credentialsProvider)
        
        //IoT control plane seem to operate on iot.<region>.amazonaws.com
        //Set the defaultServiceConfiguration so that when we call AWSIoTManager.default(), it will get picked up
        AWSServiceManager.default().defaultServiceConfiguration = controlPlaneServiceConfiguration
        iotManager = AWSIoTManager.default()
        iot = AWSIoT.default()
    }
    
    func initializeDataPlane(credentialsProvider: AWSCredentialsProvider) {
        //Initialize Dataplane:
        // IoT Dataplane must use your account specific IoT endpoint

        // let iotEndPoint = AWSEndpoint(urlString: IOT_ENDPOINT)
        
        let iotEndPoint = AWSEndpoint(urlString: selectedAWSEndPoint)
        
        // Configuration for AWSIoT data plane APIs
        let iotDataConfiguration = AWSServiceConfiguration(region: AWS_REGION,
                                                           endpoint: iotEndPoint,
                                                           credentialsProvider: credentialsProvider)
        //IoTData manager operates on xxxxxxx-iot.<region>.amazonaws.com
        AWSIoTDataManager.register(with: iotDataConfiguration!, forKey: AWS_IOT_DATA_MANAGER_KEY)
        iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
    }
    
    func startNetworkSlowTimer(timeout: TimeInterval = 30.0, onTimeout: @escaping () -> Void) {
        networkSlowTimer?.invalidate()
        networkSlowTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
            onTimeout()
        }
    }
    
    func invalidateNetworkSlowTimer() {
        networkSlowTimer?.invalidate()
        networkSlowTimer = nil
    }
    
    //MARK: Connect via Certificate
    func connectViaCert(ctrPath: String?, password: String, awsEndpoint: String) {
        if self.connected == false {
            selectedCertificate = ctrPath
            selectedCertificatePassword = password
            selectedAWSEndPoint = awsEndpoint
            
            initialSetupOfAWSIOT()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.handleConnectViaCert()
            }
        }else{
            handleDisconnect()
        }
    }
    
    func handleConnectViaCert() {
        
        let defaults = UserDefaults.standard
        let certificateId = defaults.string( forKey: "certificateId")
        
        print(certificateId ?? "No certificateId")
        
        if (certificateId == nil) {
            let certificateIdInBundle = searchForExistingCertificateIdInBundle { error in
                print("Certificate import error: \(error)")
                // Call mqttEventCallback with a custom error status
                self.mqttEventCallback(.connectionRefused, error: error)
            }
            
            if (certificateIdInBundle == nil) {
                
                createCertificateIdAndStoreinNSUserDefaults(onSuccess: {generatedCertificateId in
                    let uuid = UUID().uuidString
                    self.iotDataManager.connect(
                        withClientId: uuid,
                        cleanSession: true,
                        certificateId: generatedCertificateId,
                        statusCallback: { status in
                            self.mqttEventCallback(status, error: nil)
                        }
                    )
                }, onFailure: {error in
                    print("Received error: \(error)")
                })
            }
        } else {
            let uuid = UUID().uuidString;
            // Connect to the AWS IoT data plane service w/o certificate
            self.iotDataManager.connect(
                withClientId: uuid,
                cleanSession: true,
                certificateId: certificateId!,
                statusCallback: { status in
                    self.mqttEventCallback(status, error: nil)
                }
            )
        }
    }
    
    func searchForExistingCertificateIdInBundle(onFailure: @escaping (Error) -> Void) -> String? {
        let defaults = UserDefaults.standard
        let mainBundle = Bundle.main
        //let certFile = mainBundle.paths(forResourcesOfType: "p12" as String, inDirectory:nil)
        //print(certFile)
        
//        let certFile = mainBundle.path(forResource: "SilabsAWSIoTCertificate", ofType: "p12")
//        print("SilabsAWSIoTCertificate: ************ \(certFile!)")
        
        //NSString *p12Path = [[NSBundle mainBundle] pathForResource:@"TLSCertificate" ofType:@"p12"];
        let uuid = UUID().uuidString
        
//        guard let certId = certFile else {
//            let certificateId = defaults.string(forKey: "certificateId")
//            return certificateId
//        }
        
        guard let certId = selectedCertificate else {
            let certificateId = defaults.string(forKey: "certificateId")
            return certificateId
        }
        
        // A PKCS12 file may exist in the bundle.  Attempt to load the first one
        // into the keychain (the others are ignored), and set the certificate ID in the
        // user defaults as the filename.  If the PKCS12 file requires a passphrase,
        // you'll need to provide that here; this code is written to expect that the
        // PKCS12 file will not have a passphrase.
        
//        guard let data = try? Data(contentsOf: URL(fileURLWithPath: certId)) else {
//            print("[ERROR] Found PKCS12 File in bundle, but unable to use it")
//            let certificateId = defaults.string( forKey: "certificateId")
//            return certificateId
//        }
        
        guard FileManager.default.fileExists(atPath: certId) else {
            let error = NSError(domain: "PKCS12", code: -3, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid certificate and its corresponding password."])
            onFailure(error)
            return nil
        }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: certId)) else {
                let error = NSError(domain: "PKCS12", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid certificate and its corresponding password."])
                onFailure(error)
                return nil
            }
        
        // if AWSIoTManager.importIdentity( fromPKCS12Data: data, passPhrase:"1234567890", certificateId:certId) {
        if AWSIoTManager.importIdentity( fromPKCS12Data: data, passPhrase: selectedCertificatePassword, certificateId:certId) {

            // Set the certificate ID and ARN values to indicate that we have imported
            // our identity from the PKCS12 file in the bundle.
            defaults.set(certId, forKey:"certificateId")
            defaults.set("from-bundle", forKey:"certificateArn")
            DispatchQueue.main.async {
                print("Final uuid:= \(uuid)")
                print("Final ctrid:= \(certId)")
                
                self.iotDataManager.connect(
                    withClientId: uuid,
                    cleanSession: true,
                    certificateId: certId,
                    statusCallback: { status in
                        self.mqttEventCallback(status, error: nil)
                    }
                )
            }
        } else {
            let error = NSError(domain: "PKCS12", code: -2, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid certificate and its corresponding password."])
            onFailure(error)
            return nil
        }
        
        let certificateId = defaults.string( forKey: "certificateId")
        return certificateId
    }
    
    func createCertificateIdAndStoreinNSUserDefaults(onSuccess:  @escaping (String)->Void,
                                                     onFailure: @escaping (Error) -> Void) {
        let defaults = UserDefaults.standard
        // Now create and store the certificate ID in NSUserDefaults
        let csrDictionary = [ "commonName": CertificateSigningRequestCommonName,
                              "countryName": CertificateSigningRequestCountryName,
                              "organizationName": CertificateSigningRequestOrganizationName,
                              "organizationalUnitName": CertificateSigningRequestOrganizationalUnitName]
        
        self.iotManager.createKeysAndCertificate(fromCsr: csrDictionary) { (response) -> Void in
            guard let response = response else {
                onFailure(NSError(domain: "No response on iotManager.createKeysAndCertificate", code: -2, userInfo: nil))
                return
            }
            defaults.set(response.certificateId, forKey:"certificateId")
            defaults.set(response.certificateArn, forKey:"certificateArn")
            let certificateId = response.certificateId
            print("response: [\(String(describing: response))]")
            
            let attachPrincipalPolicyRequest = AWSIoTAttachPrincipalPolicyRequest()
            attachPrincipalPolicyRequest?.policyName = POLICY_NAME
            attachPrincipalPolicyRequest?.principal = response.certificateArn
            
            // Attach the policy to the certificate
            self.iot.attachPrincipalPolicy(attachPrincipalPolicyRequest!).continueWith (block: { (task) -> AnyObject? in
                if let error = task.error {
                    print("Failed: [\(error)]")
                    onFailure(error)
                } else  {
                    print("result: [\(String(describing: task.result))]")
                    DispatchQueue.main.asyncAfter(deadline: .now()+2, execute: {
                        if let certificateId = certificateId {
                            onSuccess(certificateId)
                        } else {
                            onFailure(NSError(domain: "Unable to generate certificate id", code: -1, userInfo: nil))
                        }
                    })
                }
                return nil
            })
        }
    }
    
    // MARK: Handel Connect via Certificate
    func mqttEventCallback( _ status: AWSIoTMQTTStatus, error: Error? ) {
        DispatchQueue.main.async {
            print("connection status = \(status.rawValue)")
            
            switch status {
            case .connecting:
                print( "connecting" )
                
            case .connected:
                print("Connected" )
                self.connected = true
                self.SILSmartLockAWSViewModelDelegate?.notifySmartLockConnectionStatus(isConeected: self.connected, status: status, msg: " Successfully Connected")

            case .disconnected:
                print("Disconnected")
                self.connected = false
                self.SILSmartLockAWSViewModelDelegate?.notifySmartLockConnectionStatus(isConeected: self.connected, status: status, msg: "Disconnected: \(error?.localizedDescription ?? "")")
                
            case .connectionRefused:
                print( "Connection Refused" )
                self.connected = false
                self.SILSmartLockAWSViewModelDelegate?.notifySmartLockConnectionStatus(isConeected: self.connected, status: status, msg: "Connection Refused: \(error?.localizedDescription ?? "")")
                
            case .connectionError:
                print( "Connection Error" )
                self.connected = false
                self.SILSmartLockAWSViewModelDelegate?.notifySmartLockConnectionStatus(isConeected: self.connected, status: status, msg: "Connection Error: \(error?.localizedDescription ?? "")")
                
            case .protocolError:
                print( "Protocol Error" )
                self.connected = false
                self.SILSmartLockAWSViewModelDelegate?.notifySmartLockConnectionStatus(isConeected: self.connected, status: status, msg: "Protocol Error: \(status.rawValue)")
            default:
                print("unknown state: \(status.rawValue)")
                self.connected = false
                self.SILSmartLockAWSViewModelDelegate?.notifySmartLockConnectionStatus(isConeected: self.connected, status: status, msg: "unknown state: \(status.rawValue)")
            }
            
            NotificationCenter.default.post( name: Notification.Name(rawValue: "connectionStatusChanged"), object: self )
        }
    }
    
    //MARK: - Connected via Web Soket
    
    func connectByWebSocketClicked() {
        if (connected == false) {
            handleConnectViaWebsocket()
        } else {
            handleDisconnect()
        }
    }
    
    // MARK: handle Connect Via Websocket/using pool id
    func handleConnectViaWebsocket() {
        let uuid = UUID().uuidString
        iotDataManager.connectUsingWebSocket(withClientId: uuid, cleanSession: true, statusCallback: mqttEventCallbackWebsocket(_:))
    }
    
    func mqttEventCallbackWebsocket(_ status: AWSIoTMQTTStatus) {
        guard case .connected = status else {
            mqttEventCallback(status, error: nil)
            return
        }
        self.connected = true
    }
    
    // MARK: Disconnect connection
    func handleDisconnect() {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            self.iotDataManager?.disconnect();
            DispatchQueue.main.async {
                self.connected = false
                UserDefaults.standard.removeObject(forKey: "certificateId")
            }
        }
    }
    
    // MARK: - Smart Lock Control Methods
    
    func lockDevice(pubTopic: String, onNetworkSlow: @escaping () -> Void) {
        startNetworkSlowTimer(onTimeout: onNetworkSlow)
        iotDataManager?.publishString(SmartLockConstants.lockCommand, onTopic: pubTopic, qoS: .messageDeliveryAttemptedAtMostOnce)
    }
        
    func unlockDevice(pubTopic: String, onNetworkSlow: @escaping () -> Void) {
        startNetworkSlowTimer(onTimeout: onNetworkSlow)
        iotDataManager?.publishString(SmartLockConstants.unlockCommand, onTopic: pubTopic, qoS: .messageDeliveryAttemptedAtMostOnce)
    }
        
    func getQueryStatus(pubTopic: String, onNetworkSlow: @escaping () -> Void) {
        startNetworkSlowTimer(onTimeout: onNetworkSlow)
        iotDataManager?.publishString(SmartLockConstants.wakeupQuery, onTopic: pubTopic, qoS: .messageDeliveryAttemptedAtMostOnce)
    }
    
    func sendCustomMessage(pubTopic: String, message: String, onNetworkSlow: @escaping () -> Void) {
        startNetworkSlowTimer(onTimeout: onNetworkSlow)
        iotDataManager?.publishString(message, onTopic: pubTopic, qoS: .messageDeliveryAttemptedAtMostOnce)
    }

}
