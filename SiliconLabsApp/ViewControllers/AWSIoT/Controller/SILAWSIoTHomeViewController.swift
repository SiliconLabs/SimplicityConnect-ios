//
//  SILAWSIoTHomeViewController.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 19/02/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

import UIKit
import AWSIoT
import Network
import SVProgressHUD

class SILAWSIoTHomeViewController: UIViewController, UITextFieldDelegate, SILAWSIoTHomeViewModelProtocol, SILAWSIoTSubscribeViewModelProtocol, SILAWSIoTLEDControllerProtocol {

    @IBOutlet weak var pubTextField: UITextField!
    @IBOutlet weak var subTextField: UITextField!
    @IBOutlet weak var subContainerView: UIView!
    @IBOutlet weak var pubContainerView: UIView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var noDataView: UIView!
    @IBOutlet weak var connectView: UIView!

    let storyboardAWSIoT = UIStoryboard(name: "SILAWSIoT", bundle: .main)

    var SILAWSIoTHomeViewModelObj: SILAWSIoTHomeViewModel?
    var SILAWSIoTSubscribeViewModelObj: SILAWSIoTSubscribeViewModel?
    
    var sensorsData: [Any] = []
    
    var isValidTopic: Bool = false
    var onlineStatus: Bool = false
    var offlineAlertStatus: Bool = false
    var onlineAlertStatus: Bool = false
    var getPublishData: Bool = false
    
    var timer: Timer?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        SILAWSIoTHomeViewModelObj = SILAWSIoTHomeViewModel(SILAWSIoTHomeViewModelDelegate: self)
        SILAWSIoTSubscribeViewModelObj = SILAWSIoTSubscribeViewModel(SILAWSIoTSubscribeViewModelDelegate: self, sensorsData: [])
        sensorsData = []
        sensorsData = SILAWSIoTSubscribeViewModelObj?.createCollectionArray() ?? []
        updateUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.networkStatusChanged(_:)), name: Notification.Name(rawValue: ReachabilityStatusChangedNotification), object: nil)
        Reachability().monitorReachabilityChanges()
        onlineStatus = false
        getPublishData = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        unsubscribeTopic()
        SILAWSIoTHomeViewModelObj?.handleDisconnect()
    }
    //MARK: private func
    private func updateUI() {
        setLeftAlignedTitle("AWS Dashboard")
        noDataView.isHidden = true
        subContainerView.layer.borderColor = UIColor.lightGray.cgColor
        subContainerView.layer.borderWidth = 1
        subContainerView.layer.cornerRadius = 5
        pubContainerView.layer.borderColor = UIColor.lightGray.cgColor
        pubContainerView.layer.borderWidth = 1
        pubContainerView.layer.cornerRadius = 5

        let nib = UINib(nibName: "SILAWSIoTValueCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "SILAWSIoTValueCell")
        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        collectionView.dataSource = self
       // connectView.isHidden = false
        showConnectView()
        
        if let subTopicStr = AWStopicUserDefault.string(forKey: subcribe_topic_name) {
           //print(subTopicStr)
            subTextField.text = subTopicStr
        }
        if let pubTopicStr = AWStopicUserDefault.string(forKey: publish_topic_name) {
           //print(pubTopicStr)
            pubTextField.text = pubTopicStr
        }
        
//        subTextField.addTarget(self,
//                            action: #selector(self.textFieldDidChange(_:)),
//                            for: UIControl.Event.editingChanged)
//        pubTextField.addTarget(self,
//                            action: #selector(self.textFieldDidChange(_:)),
//                            for: UIControl.Event.editingChanged)
    }
    
    private func unsubscribeTopic() {
        if let subTopicStr = AWStopicUserDefault.string(forKey: subcribe_topic_name) {
          // print(subTopicStr)
            let iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
            iotDataManager.unsubscribeTopic(subTopicStr)
        }
    }
    private func dismissLoader(){
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { timer in
            SVProgressHUD.dismiss()
//            if !self.getPublishData {
//                self.showConnectView()
//            }
        }

    }

    private func showConnectView(){
        UIView.transition(with: self.connectView, duration: 0.4,
                          options: .transitionCrossDissolve,
                          animations: {
            self.connectView.isHidden = false
        })
    }
   
    
    //MARK: @IBAction
    @IBAction func connectBtn(_ sender: UIButton) {
        guard subTextField.isValid(with: subTextField.text!), pubTextField.isValid(with: pubTextField.text!) else {
           print("Text Fields are not validated, disable everything! ❌")
            isValidTopic = false
            self.alertWithOKButton(title: "Alert!", message: "Subscribe and publish topics should not be empty.", completion: { _ in
            })
           return
          }
          print("Text Fields are validated, enable everything! ✅")
        isValidTopic = true
        if isValidTopic {
           if onlineStatus {
                self.getPublishData = false
                SVProgressHUD.show(withStatus: "Connecting")
                SILAWSIoTHomeViewModelObj?.connectViaCert()
                if let subTopicName = subTextField.text {
                    AWStopicUserDefault.set(subTopicName, forKey: subcribe_topic_name)
                }
                if let pubTopicName = pubTextField.text {
                    AWStopicUserDefault.set(pubTopicName, forKey: publish_topic_name)
                }
                dismissLoader()
            }else{
                DispatchQueue.main.async {
                    self.showToast(message:"Internet not available. Kindly check your internet connection on your phone. Thank you!", toastType: .disconnectionError, completion: {})
                }
            }
        }else{
            self.alertWithOKButton(title: "Alert!", message: "Subscribe and publish topics should not be empty.", completion: { _ in
            })
        }
       // guard let subTopicName = subTextField.text,
    }
    
    @IBAction func cancelBtn(_ sender: UIButton) {
      self.navigationController?.popViewController(animated: true)
       // self.connectView.isHidden =  true
    }
    
    
    
    //MARK: SILAWSIoTHomeViewModelProtocol
    func notifyAWSIoTConnectionStatus(isConeected: Bool, status: AWSIoTMQTTStatus, msg: String) {
        if isConeected{
            self.getPublishData = false
            if let subTopicStr = AWStopicUserDefault.string(forKey: subcribe_topic_name) {
              // print(subTopicStr)
                SILAWSIoTSubscribeViewModelObj?.subscribeOverTopic(topicId: subTopicStr)

            }
            DispatchQueue.main.async {
                //self.subValueTextView.text = "\(stringValue)"
                self.connectView.isHidden =  true
            }
        }else{
            self.getPublishData = false
            SILAWSIoTHomeViewModelObj?.handleDisconnect()
            DispatchQueue.main.async {
                self.showToast(message:msg, toastType: .disconnectionError, completion: {})
                self.sensorsData = []
                self.sensorsData = self.SILAWSIoTSubscribeViewModelObj?.createCollectionArray() ?? []
                self.collectionView.reloadData()
                //self.connectView.isHidden =  false
                self.showConnectView()
            }
        }
    }
    //MARK: SILAWSIoTSubscribeViewModelProtocol
    func notifyAWSIoTSubscribeData(subscribeData: [Any]) {
        if subscribeData.count > 0 {
            //getPublishData = true
            sensorsData = []
            sensorsData = subscribeData
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
           // print("************* \(subscribeData)")
            for subVal in subscribeData {
                if let valTemp = subVal as? Dictionary<String, Any> {
                    //print("+++++++++++++++++++ \(valTemp["title"] ?? "")")
                    switch "\(valTemp["title"] ?? "")" {
                    case SensorType.motion.rawValue:
                       // print("============= \(valTemp["title"] ?? "")")
                        let motionValue = ["mVal": valTemp]
                        // post a notification
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: notification_motion), object: nil, userInfo: motionValue)
                        
                    default:
                        print("Have you done something new?")
                    }
                }
          
            }
            
         

        }
    }
    //MARK: SILAWSIoTLEDControllerProtocol
    func notifyAWSIoTPublishViewClose(isClose: Bool) {
        if let subTopicStr = AWStopicUserDefault.string(forKey: subcribe_topic_name) {
          // print(subTopicStr)
            SILAWSIoTSubscribeViewModelObj?.subscribeOverTopic(topicId: subTopicStr)
        }
        DispatchQueue.main.async {
            //self.subValueTextView.text = "\(stringValue)"
            self.connectView.isHidden =  true
        }
    }
    
//MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
         textField.resignFirstResponder()
         return true
    }
//    @objc func textFieldDidChange(_ textField: UITextField) {
//        //Here we will write some code, bear with me!
//        guard subTextField.isValid(with: subTextField.text!), pubTextField.isValid(with: pubTextField.text!) else {
//           print("Text Fields are not validated, disable everything! ❌")
//            isValidTopic = false
//           return
//          }
//          print("Text Fields are validated, enable everything! ✅")
//        isValidTopic = true
//    }
    
    //MARK: Network Reachability
    @objc func networkStatusChanged(_ notification: Notification) {
       // print(notification.userInfo)
        if let notificationVal = notification.userInfo?["Status"] as? String {
            // do something with your image
            //print(notificationVal)
            if notificationVal == "Offline"  {
                onlineStatus = false
                onlineAlertStatus = false
                if !offlineAlertStatus {
                    offlineAlertStatus = true
                    DispatchQueue.main.async {
                        self.showToast(message:"Internet not available. Kindly check your internet connection on your phone. Thank you!", toastType: .disconnectionError, completion: {})
                    }
                }
            }else{
                offlineAlertStatus = false
                onlineStatus = true
                if !onlineAlertStatus {
                    onlineAlertStatus = true
                    DispatchQueue.main.async {
                        self.showToast(message:"The device is reconnected to the internet.", toastType: .internetInfo, completion: {})
                    }
                }
            }
        }

    }
}
extension SILAWSIoTHomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sensorsData.count
    }
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
//        {
//           return CGSize(width: 109.0, height: 117.0)
//        }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SILAWSIoTValueCell", for: indexPath as IndexPath) as? SILAWSIoTValueCell else { return UICollectionViewCell() }
        cell.updateSensorValue(sensorsData: sensorsData[indexPath.row] as! Dictionary<String, Any>)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 10, bottom: 20, right: 10)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCell(cellIndex: indexPath.row)
    }
    func selectedCell(cellIndex: Int) {
        if let sensorsDataDic: Dictionary = sensorsData[cellIndex] as? Dictionary<String, Any>{
            switch "\(sensorsDataDic["title"] ?? "")" {
            
            case SensorType.led.rawValue:
                //SILAWSIoTLEDController
                unsubscribeTopic()
                let SILAWSIoTLEDControllerObj = storyboardAWSIoT.instantiateViewController(withIdentifier: "SILAWSIoTLEDController") as! SILAWSIoTLEDController
                SILAWSIoTLEDControllerObj.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                SILAWSIoTLEDControllerObj.ledIntialData = sensorsDataDic
                SILAWSIoTLEDControllerObj.SILAWSIoTLEDControllerDelegate = self
                present(SILAWSIoTLEDControllerObj, animated: false)
            case SensorType.motion.rawValue:

                let SILAWSIoTMotionViewControllerObj = storyboardAWSIoT.instantiateViewController(withIdentifier: "SILAWSIoTMotionViewController") as! SILAWSIoTMotionViewController
                SILAWSIoTMotionViewControllerObj.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                SILAWSIoTMotionViewControllerObj.motionData = sensorsDataDic
                present(SILAWSIoTMotionViewControllerObj, animated: false)
                
            default:
                print("Have you done something new?")
            }
        }
    }
}

