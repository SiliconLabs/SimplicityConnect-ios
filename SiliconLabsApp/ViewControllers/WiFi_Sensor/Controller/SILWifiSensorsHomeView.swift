//
//  SILWifiSensorsHomeView.swift
//  BlueGecko
//
//  Created by Mantosh Kumar on 05/04/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit
import SVProgressHUD

class SILWifiSensorsHomeView: UIViewController, SILWiFiSensorsViewModelProtocol {
    
    @IBOutlet weak var sensoreValueLbl: UILabel!
    @IBOutlet weak var sensoreImg: UIImageView!
    @IBOutlet weak var sensoreTitleLbl: UILabel!
    @IBOutlet weak var sensorePopupViewTitle: UILabel!
    @IBOutlet weak var sensorePopupView: UIView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var noDataView: UIView!
    
    //var timer = Timer()
    var sensorsData: [Any] = []
    var sensorTypeStr: String = ""
    var apiCallTimer: Timer?
    
    var silwifiSensorsViewModelObject:SILWiFiSensorsViewModel = SILWiFiSensorsViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //silwifiSensorsViewModelObject.checkServerAvailability()
        //setupNavigationBar()
        silwifiSensorsViewModelObject.SILWiFiSensorsViewModelDelegate = self
        updateUI()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SVProgressHUD.show(withStatus: "Connecting")
        sensorTypeStr = ""
        silwifiSensorsViewModelObject.getTemperatureData { sensorsData, APIClientError in
            if APIClientError == nil{
                DispatchQueue.main.async {
                    self.silwifiSensorsViewModelObject.getAllSensorData()
                    //self.silwifiSensorsViewModelObject.getAllSensor()
                }
            }else{
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    private func updateUI() {
        setLeftAlignedTitle("WiFi Sensors")
        let nib = UINib(nibName: "SILSensorCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "SILSensorCell")
        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        sensorePopupView.isHidden = true
    }
    
 @IBAction func cancelBtn(_ sender: UIButton) {
        sensorePopupView.isHidden = true
        sensorTypeStr = ""
        if self.apiCallTimer != nil{
            self.apiCallTimer?.invalidate()
            self.apiCallTimer = nil
        }
       
    }
    @IBAction func refreshBtn(_ sender: UIButton) {
        if sensorTypeStr == SensorType.temp.rawValue {
            self.getTemp()
        }else if sensorTypeStr == SensorType.humudity.rawValue {
            self.getHumudity()
        }else if sensorTypeStr == SensorType.ambient.rawValue {
            self.getAmbient()
        }
    }
    
}
extension SILWifiSensorsHomeView {
    
    func notifySensorsData(sensorsData: [Any]) {
        self.sensorsData = sensorsData
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            if self.sensorsData.count > 0 {
                self.noDataView.isHidden = true
                self.collectionView.isHidden = false
            }else{
                self.noDataView.isHidden = false
                self.collectionView.isHidden = true
            }
            self.collectionView.reloadData()
        }
    }
}

extension SILWifiSensorsHomeView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sensorsData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SILSensorCell", for: indexPath as IndexPath) as? SILSensorCell else { return UICollectionViewCell() }
        cell.updateSensorValue(sensorsData: sensorsData[indexPath.row] as! Dictionary<String, Any>)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 10, bottom: 20, right: 10)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedSensor(cellIndex: indexPath.row)
    }

}
extension SILWifiSensorsHomeView {
    
    func setTimer(apiType: String){
        if apiType == SensorType.temp.rawValue {
            if self.apiCallTimer != nil{
                self.apiCallTimer?.invalidate()
                self.apiCallTimer = nil
            }
            apiCallTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: { [weak self] (timer) in
                //self?.getRequest()
                self?.getTemp()
            })
        }else if apiType == SensorType.humudity.rawValue {
            if self.apiCallTimer != nil{
                self.apiCallTimer?.invalidate()
                self.apiCallTimer = nil
            }
            apiCallTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: { [weak self] (timer) in
                //self?.getRequest()
                self?.getHumudity()
            })
        }else if apiType == SensorType.ambient.rawValue {
            if self.apiCallTimer != nil{
                self.apiCallTimer?.invalidate()
                self.apiCallTimer = nil
            }
            apiCallTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: { [weak self] (timer) in
                //self?.getRequest()
                self?.getAmbient()
            })
            
        }
    }
    func getTemp(){
        silwifiSensorsViewModelObject.getTemperatureData { sensorsData, APIClientError in
            if APIClientError == nil{
                if let ledDic: Dictionary = sensorsData {
                    DispatchQueue.main.async {
                        self.setPopUpData(sensorePopupViewTitle: SensorePopupViewName.temperaturePopupViewTitle.rawValue, sensoreTitleLbl: SensorTitle.temperatureTitle.rawValue, sensoreImg: SensorImage.temp ?? UIImage(), sensoreValueLbl: "\(ledDic["temperature_celcius"] ?? "")°C")
                    }
                }
            }
        }
    }
    func getHumudity() {
        silwifiSensorsViewModelObject.getHumidityData { sensorsData, APIClientError in
            if APIClientError == nil{
                if let ledDic: Dictionary = sensorsData {
                    DispatchQueue.main.async {
                        self.setPopUpData(sensorePopupViewTitle: SensorePopupViewName.humudityPopupViewTitle.rawValue, sensoreTitleLbl: SensorTitle.humudityTitle.rawValue, sensoreImg: SensorImage.humidity ?? UIImage(), sensoreValueLbl: "\(ledDic["humidity_percentage"] ?? "")%")
                    }
                }
            }
        }
    }
    func getAmbient() {
        silwifiSensorsViewModelObject.getLightData { sensorsData, APIClientError in
            if APIClientError == nil{
                if let ledDic: Dictionary = sensorsData {
                    DispatchQueue.main.async {
                        self.setPopUpData(sensorePopupViewTitle: SensorePopupViewName.ambientLightPopupViewTitle.rawValue, sensoreTitleLbl: SensorTitle.ambientLightTitle.rawValue, sensoreImg: SensorImage.ambient ?? UIImage(), sensoreValueLbl: "\(ledDic["ambient_light_lux"] ?? "") lx")
                    }
                }
            }
        }
    }
}
extension SILWifiSensorsHomeView {
    func setPopUpData(sensorePopupViewTitle: String, sensoreTitleLbl: String, sensoreImg: UIImage, sensoreValueLbl: String) {
        self.sensorePopupViewTitle.text = sensorePopupViewTitle
        self.sensoreTitleLbl.text = sensoreTitleLbl
        self.sensoreImg.image = sensoreImg
        self.sensoreValueLbl.text = sensoreValueLbl
    }
    
    func selectedSensor(cellIndex: Int) {
        let storyboard = UIStoryboard(name: "SILWifiSensors", bundle: .main)
        if let sensorsDataDic: Dictionary = sensorsData[cellIndex] as? Dictionary<String, Any>{
            switch "\(sensorsDataDic["title"] ?? "")" {
            case SensorType.temp.rawValue:
                sensorePopupView.isHidden = false
                self.sensorTypeStr = SensorType.temp.rawValue
                self.setPopUpData(sensorePopupViewTitle: SensorePopupViewName.temperaturePopupViewTitle.rawValue, sensoreTitleLbl: SensorTitle.temperatureTitle.rawValue, sensoreImg: SensorImage.temp ?? UIImage(), sensoreValueLbl: "\(sensorsDataDic["value"] ?? "")°C")
               self.setTimer(apiType: SensorType.temp.rawValue)
             case SensorType.humudity.rawValue:
                sensorePopupView.isHidden = false
                self.sensorTypeStr = SensorType.humudity.rawValue
                self.setPopUpData(sensorePopupViewTitle: SensorePopupViewName.humudityPopupViewTitle.rawValue, sensoreTitleLbl: SensorTitle.humudityTitle.rawValue, sensoreImg: SensorImage.humidity ?? UIImage(), sensoreValueLbl: "\(sensorsDataDic["value"] ?? "")%")
                self.setTimer(apiType: SensorType.humudity.rawValue)
            case SensorType.ambient.rawValue:
                sensorePopupView.isHidden = false
                self.sensorTypeStr = SensorType.ambient.rawValue
                self.setPopUpData(sensorePopupViewTitle: SensorePopupViewName.ambientLightPopupViewTitle.rawValue, sensoreTitleLbl: SensorTitle.ambientLightTitle.rawValue, sensoreImg: SensorImage.ambient ?? UIImage(), sensoreValueLbl: "\((sensorsDataDic["value"] as? [String: Any])?["ambient_light_lux"] ?? "") lx")
                self.setTimer(apiType: SensorType.ambient.rawValue)
            case SensorType.led.rawValue:
                sensorePopupView.isHidden = true
                let SILWiFiLEDViewControllerObj = storyboard.instantiateViewController(withIdentifier: "SILWiFiLEDViewController")
                SILWiFiLEDViewControllerObj.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                present(SILWiFiLEDViewControllerObj, animated: false)

                //navigationController?.pushViewController(SILWiFiLEDViewControllerObj, animated: true)
            case SensorType.motion.rawValue:
                sensorePopupView.isHidden = true
                //SILWiFiMotionVcCh
                //let SILWiFiMotionViewControllerObj = storyboard.instantiateViewController(withIdentifier: "SILWiFiMotionVcCh")
                let SILWiFiMotionViewControllerObj = storyboard.instantiateViewController(withIdentifier: "SILWiFiMotionViewController")
                SILWiFiMotionViewControllerObj.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                present(SILWiFiMotionViewControllerObj, animated: false)
                
            default:
                print("Have you done something new?")
            }
        }
    }
}

extension SILWifiSensorsHomeView: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
}

