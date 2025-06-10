//
//  SILWifiProvisioningAPViewController.swift
//  BlueGecko
//
//  Created by SovanDas Maity on 25/07/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

import UIKit
import SVProgressHUD

class SILWifiProvisioningAPViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SILWifiProvisioningAPViewModelProtocol, SILWiFiProvisionViewControllerProtocol {
  
    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var noDataView: UIView!
    
    @IBOutlet weak var APTableView: UITableView!
    
    
   private var wifiProvisioningAPViewModelObje:SILWifiProvisioningAPViewModel = SILWifiProvisioningAPViewModel()
    var allAP: [ScanResult] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        intialUI()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        SVProgressHUD.show(withStatus: "Connecting")
        wifiProvisioningAPViewModelObje.apiCallForIntialLoad()
        
//        wifiProvisioningAPViewModelObje.getAPIForWifiProvision(apiEndPoint: "scan") { [self] (_ apList: SILAPDataList?, APIClientError) in
//            DispatchQueue.main.async {
//                SVProgressHUD.dismiss()
//            }
//            if APIClientError == nil{
//                if let apListTemp = apList {
//                    allAP = apListTemp.scanResults
//                    reRenderListView()
//                }
//            }else{
//                print(APIClientError?.localizedDescription.description ?? "")
//                DispatchQueue.main.async { [self] in
//                    noDataView.isHidden = false
//                    descriptionView.isHidden = true
//                    showAlert(message: APIClientError?.localizedDescription.description ?? "")
//                }
//            }
//        }
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //self.tabBarController?.tabBar.isHidden = true
    }
    
    private func reRenderListView() {
        DispatchQueue.main.async { [self] in
            noDataView.isHidden = true
            descriptionView.isHidden = false
            APTableView.reloadData()
        }
    }
    
    private func intialUI(){
        setLeftAlignedTitle("WiFi Provisioning")
        //self.navigationItem.title = "WiFi Provisioning"
        self.tabBarController?.tabBar.isHidden = true
        APTableView.backgroundColor = UIColor.clear
        APTableView.delegate = self
        APTableView.dataSource =  self
        APTableView.showsVerticalScrollIndicator = false
        APTableView.showsHorizontalScrollIndicator = false
        noDataView.isHidden = true
        descriptionView.isHidden = true
        wifiProvisioningAPViewModelObje.SILWifiProvisioningAPViewModelDelegate = self
    }
    private func showAlert(message: String, title: String) {
        self.alertWithOKButton(title: title, message: message, completion: { _ in
            self.navigationController?.popViewController(animated: true)
        })
    }
}

extension SILWifiProvisioningAPViewController {
    func numberOfSections(in tableView: UITableView) -> Int {
          return 1
      }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allAP.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = APTableView.dequeueReusableCell(withIdentifier: "SILWifiProvisioningAPViewCell", for: indexPath) as! SILWifiProvisioningAPViewCell
        cell.updateAPCell(cellData: allAP[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "WiFiProvisioning", bundle: .main)
        let SILWiFiProvisionViewControllerObj = storyboard.instantiateViewController(withIdentifier: "SILWiFiProvisionViewController") as! SILWiFiProvisionViewController
        SILWiFiProvisionViewControllerObj.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        SILWiFiProvisionViewControllerObj.selectedCellData = allAP[indexPath.row]
        SILWiFiProvisionViewControllerObj.SILWiFiProvisionViewControllerDelegate = self
        present(SILWiFiProvisionViewControllerObj, animated: false)
    }

}

extension SILWifiProvisioningAPViewController {
    
    func notifyAPData(APData: [ScanResult]?, apiResponseError: Error? ) {
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
        }
        if APData != nil {
            allAP = APData ?? []
            reRenderListView()
        }else{
            //print(APIClientError?.localizedDescription.description ?? "")
            DispatchQueue.main.async { [self] in
                noDataView.isHidden = false
                descriptionView.isHidden = true
                showAlert(message: apiResponseError?.localizedDescription.description ?? "", title: "Error!")
            }
        }
    }
    
    func provisioningStatus(isComplete: Bool) {
        if isComplete {
            //alertView(alertTitle: "Success", alertMsg: "Provisioning completed successfully.", alertType: "")
            showAlert(message: "The white light is continuous and blinks slowly, indicating that the device is connected to the Wi-Fi network.", title: "Provisioning data sent successfully")
        }
    }
    func alertView(alertTitle: String, alertMsg: String, alertType: String){
        DispatchQueue.main.async {
            let alert = UIAlertController(title: alertTitle, message: alertMsg, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: {_ in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
        }

    }
}
