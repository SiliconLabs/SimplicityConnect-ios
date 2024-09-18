

// module header
#import "QRCodeViewController.h"

// local imports
#import "CHIPUIViewUtils.h"
#import "DefaultsUtils.h"
#import "DeviceSelector.h"
#import <Matter/MTRDeviceAttestationDelegate.h>
#import <Matter/MTRSetupPayload.h>
#import <Matter/Matter.h>
#import <SVProgressHUD/SVProgressHUD.h>

#define INDICATOR_DELAY 0.5 * NSEC_PER_SEC
#define ERROR_DISPLAY_TIME 2.0 * NSEC_PER_SEC
#define kOFFSET_FOR_KEYBOARD 180.0

// The expected Vendor ID for CHIP demos
// 0xFFF1: Chip's Vendor Id
#define EXAMPLE_VENDOR_ID 0xFFF1

#define EXAMPLE_VENDOR_TAG_IP 1
#define MAX_IP_LEN 46

#define NETWORK_CHIP_PREFIX @"CHIP-"

@interface QRCodeViewController ()

@property (nonatomic, strong) AVCaptureSession * captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * videoPreviewLayer;

@property (strong, nonatomic) NSDictionary * ledgerRespond;

@property (strong, nonatomic) UIActivityIndicatorView * activityIndicator;
@property (strong, nonatomic) UILabel * errorLabel;

@property (readwrite) MTRDeviceController * chipController;
@property (nonatomic, strong) MTRBaseClusterNetworkCommissioning * cluster;

@property (strong, nonatomic) NFCNDEFReaderSession * session;
@property (strong, nonatomic) MTRSetupPayload * setupPayload;
@property (strong, nonatomic) DeviceSelector * deviceList;
@property (strong, nonatomic) NSData * datasetValue;
@property (strong, nonatomic) NSMutableArray * deviceListVal;

@property (strong, nonatomic) MTRDescriptorClusterDeviceTypeStruct * descriptorClusterDeviceTypeStruct;
@property (strong, nonatomic) NSMutableArray * deviceListTemp;
@property (strong, nonatomic) UITextField * passTextField;

@end

@interface CHIPToolDeviceAttestationDelegate : NSObject <MTRDeviceAttestationDelegate>

@property (weak, nonatomic) QRCodeViewController * viewController;
- (instancetype)initWithViewController:(QRCodeViewController *)viewController;
@end

@implementation QRCodeViewController {
    dispatch_queue_t _captureSessionQueue;
}

NSString * isThread;
NSMutableArray * MKdeviceListTemp;
UIButton * eyeButton;
UIAlertController * alertControllerWifi;
BOOL passIsShow;
NSString *ssidStr;
NSString *passwordStr;
NSNumber * nodeIdAfterCommision;
NSNumber * deviceTypeAfterCommission;
NSString * savedStrQrCode;
NSError * savedError;

// MARK: UI Setup

- (void)setupUI {
    self.navigationItem.title = @"Commissioning Device";
    
    self.qrView.layer.cornerRadius = 8;
    self.pairButton.layer.cornerRadius = 8;
    self.hintLbl.text = @"Please position the camera to point at the QR Code. \n\nManual QR code payload ID:";
    _qrCodeInfoView.hidden = TRUE;
    _qrCodeInfoBGView.layer.cornerRadius = 10;
    _qrCodeInfoButton.layer.cornerRadius = 5;
    _addDeviceNameView.hidden = TRUE;
    _addDeviceNamePopupView.layer.cornerRadius = 5;
    _addDeviceButton.layer.cornerRadius = 5;
}

// MARK: UIViewController methods

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [_session invalidateSession];
    _session = nil;
    NSDictionary* userInfo = @{@"controller": @"QRCodeViewController"};
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"controllerNotification"
     object:self userInfo:userInfo];
}

- (void)dismissKeyboard {
    [_manualQrCodeTextField resignFirstResponder];
    [_nameInputTextField resignFirstResponder];
    _baseViewTopConstraint.constant = 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    
    savedStrQrCode = @"";
    savedError = nil;
    dispatch_queue_t callbackQueue = dispatch_queue_create("com.csa.matter.qrcodevc.callback", DISPATCH_QUEUE_SERIAL);
    self.chipController = InitializeMTR();
    [self.chipController setDeviceControllerDelegate:self queue:callbackQueue];
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    [self manualCodeInitialState];
    [self qrCodeInitialState];
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"isLightDevice"];
    
    _deviceListVal = [[NSMutableArray alloc] init];
    _deviceListVal = [[NSUserDefaults standardUserDefaults] valueForKey:@"DEVICE_LIST"];
    
    isThread = @"";
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    _manualQrCodeTextField.delegate = self;
    _nameInputTextField.delegate = self;
    _manualQrCodeTextField.tintColor = UIColor.blackColor;
    //_manualQrCodeTextField.text =@"MT:6FCJ142C00KA0648G00";
    // Open Camera View
    [self openCameraView];
    passIsShow = FALSE;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // unregister for keyboard notifications while not visible.
    //    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    //    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)saveDevice:(NSNumber *)nodeId {
    uint64_t devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            MTRBaseClusterDescriptor * descriptorCluster =
            [[MTRBaseClusterDescriptor alloc] initWithDevice:chipDevice
                                                    endpoint:1
                                                       queue:dispatch_get_main_queue()];
            
            [descriptorCluster readAttributeDeviceListWithCompletionHandler:^( NSArray * _Nullable value, NSError * _Nullable error) {
                if (error) {
                    [SVProgressHUD dismiss];
                    [self refresh];
                    return;
                }
                self->_descriptorClusterDeviceTypeStruct = value[0];
                nodeIdAfterCommision = nodeId;
                deviceTypeAfterCommission = self->_descriptorClusterDeviceTypeStruct.deviceType;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Go back to with payload and add device
                    [SVProgressHUD dismiss];
                    [self->_delegate affterCommission:nodeId];
                    // Add device name
                    NSLog(@"Cluster DeviceType :- %@",self->_descriptorClusterDeviceTypeStruct.deviceType);

                    self->_nameInputTextField.text = [CHIPUIViewUtils addDeviceTitle:[NSString stringWithFormat:@"%@",self->_descriptorClusterDeviceTypeStruct.deviceType]]; // 269 = thread // 257 = wifi (old)
                    self->_addDeviceNameView.hidden = FALSE;
                });
            }];
        } else {
            NSLog(@"Failed to establish a connection with the device");
            NSLog(@"deviceListTemp:- %@",MKdeviceListTemp);
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
        }
    })) {
        NSLog(@"Waiting for connection with the device");
    } else {
        NSLog(@"Failed to trigger the connection with the device");
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }
}
- (void) openCameraView {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, INDICATOR_DELAY), dispatch_get_main_queue(), ^{
        [self scanningStartState];
        [self startScanning];
    });
}

- (void)setVendorIDOnAccessory {
    NSLog(@"Call to setVendorIDOnAccessory");
    if (MTRGetConnectedDevice(^(MTRBaseDevice * _Nullable device, NSError * _Nullable error) {
        if (!device) {
            NSLog(@"Status: Failed to establish a connection with the device");
        }
    })) {
        NSLog(@"Status: Waiting for connection with the device");
    } else {
        NSLog(@"Status: Failed to trigger the connection with the device");
    }
}

// MARK: MTRDeviceControllerDelegate
- (void)controller:(MTRDeviceController *)controller commissioningSessionEstablishmentDone:(NSError * _Nullable)error {
    if (error != nil) {
        NSLog(@"Got pairing error back %@", error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    } else {
        MTRDeviceController * controller = InitializeMTR();
        uint64_t deviceId = MTRGetLastPairedDeviceId();
        MTRBaseDevice * device = [controller deviceBeingCommissionedWithNodeID:@(deviceId) error:NULL];
        if (device.sessionTransportType == MTRTransportTypeBLE) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //CHANGE...
                //ALERT...
                if([isThread isEqualToString:@"THREAD"]){
                    //Commented for flow change...
                    //[self retrieveAndSendThreadCredentials];
                    
                    [self commissionWithThread:self.datasetValue];
                }else if ([isThread isEqualToString:@"WIFI"]){
                    //Commented for flow change...
                    //[self retrieveAndSendWiFiCredentials];
                    
                    [self commissionWithSSID:ssidStr password:passwordStr];
                }
                [self->_deviceList refreshDeviceList];
            });
        } else {
            MTRCommissioningParameters * params = [[MTRCommissioningParameters alloc] init];
            params.deviceAttestationDelegate = [[CHIPToolDeviceAttestationDelegate alloc] initWithViewController:self];
            params.failSafeExpiryTimeoutSecs = @600;
            [SVProgressHUD dismiss];
            
            [self showAlertPopup:kDeviceRetrievingErrorMessage];
            NSError * error;
            if (![controller commissionDevice: deviceId commissioningParams: params error: &error]) {
                NSLog(@"Failed to commission Device %llu, with error %@", deviceId, error);
            }
        }
    }
}

- (NSString *)discoveryCapabilities:(MTRSetupPayload *)payload {
    if (payload.rendezvousInformation == nil) {
        return @"Unknown";
    }
    switch ([payload.rendezvousInformation unsignedLongValue]) {
        case MTRDiscoveryCapabilitiesNone:
            return @"Unknown";
        case MTRDiscoveryCapabilitiesOnNetwork:
        case MTRDiscoveryCapabilitiesBLE:
            return @"BLE";
        case MTRDiscoveryCapabilitiesAllMask:
            return @"Default";
        case MTRDiscoveryCapabilitiesSoftAP:
            return @"Wi-Fi";
        default: return @"Default";
    }
}

// MARK: UI Helper methods

- (void) showQRCodeInfo:(MTRSetupPayload *) payload strQrCode:(NSString *)strQrCode error:(NSError *)error {
    _qrCodeInfoView.hidden = FALSE;
    
    savedStrQrCode = strQrCode;
    savedError = error;
    
    _versionLabel.text = [NSString stringWithFormat: @" Version:  %@", payload.version];
    _vendorIdLabel.text = [NSString stringWithFormat: @" Vendor ID:  %@", payload.vendorID];
    _productIdLabel.text = [NSString stringWithFormat: @" Product ID:  %@", payload.productID];
    _discriminatorLabel.text = [NSString stringWithFormat: @" Discriminator:  %@", payload.discriminator];
    if (@available(iOS 16.1, *)) {
        _setupPinCodeLabel.text = [NSString stringWithFormat: @" Set up PIN Code:  %@", payload.setUpPINCode];
    } else {
        _setupPinCodeLabel.text = @"N/A";
    }
    NSString * discoveryCapabilities = [self discoveryCapabilities: payload];
    _discoveryCapabilitiesLabel.text = [NSString stringWithFormat: @" Discovery Capabilities: %@", discoveryCapabilities];
    _commissioningFlow.text = [NSString stringWithFormat: @" Commissioning Flow:  %lu", payload.commissioningFlow];
}

- (void)manualCodeInitialState {
    _activityIndicator.hidden = YES;
    [SVProgressHUD dismiss];
    _errorLabel.hidden = YES;
}

- (void)qrCodeInitialState {
    if ([_captureSession isRunning]) {
        [_captureSession stopRunning];
    }
    if ([_activityIndicator isAnimating]) {
        [_activityIndicator stopAnimating];
    }
    _activityIndicator.hidden = YES;
    [SVProgressHUD dismiss];
    
    _captureSession = nil;
}

- (void)scanningStartState {
    _errorLabel.hidden = YES;
}

- (void)manualCodeEnteredStartState {
    [SVProgressHUD showWithStatus: @"Commissioning Device..."];
    
    _errorLabel.hidden = YES;
    _manualQrCodeTextField.text = @"";
}

- (void)postScanningQRCodeState {
    _captureSession = nil;
    [SVProgressHUD showWithStatus: @"Commissioning Device..."];
}

- (void)showError:(NSError *)error {
    [self->_activityIndicator stopAnimating];
    self->_activityIndicator.hidden = YES;
    [SVProgressHUD dismiss];
    
    self->_errorLabel.text = error.localizedDescription;
    self->_errorLabel.hidden = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, ERROR_DISPLAY_TIME), dispatch_get_main_queue(), ^{
        self->_errorLabel.hidden = YES;
    });
}

- (void)showPayload:(MTRSetupPayload *)payload rawPayload:(NSString *)rawPayload isManualCode:(BOOL)isManualCode {
    self->_errorLabel.hidden = YES;
    // reset the view and remove any preferences that were stored from a previous scan
    //    self->_setupPayloadView.hidden = NO;
    
    //    [self updateUIFields: payload rawPayload: rawPayload isManualCode: isManualCode];
    [self parseOptionalData: payload];
    [self handleRendezVous: payload rawPayload: rawPayload];
}

// Retrieve And Send WiFi Credentials
- (void)retrieveAndSendWiFiCredentials:(NSString *)strQrCode error:(NSError *)error {
    alertControllerWifi = [UIAlertController alertControllerWithTitle:@"WiFi Configuration"
                                                              message:@"Input network SSID and password that your phone is connected to."
                                                       preferredStyle:UIAlertControllerStyleAlert];
    [alertControllerWifi addTextFieldWithConfigurationHandler:^(UITextField * textField) {
        textField.placeholder = @"Network SSID";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
        
        NSString * networkSSID = MTRGetDomainValueForKey(MTRToolDefaultsDomain, kNetworkSSIDDefaultsKey);
        if ([networkSSID length] > 0) {
            textField.text = networkSSID;
        }
    }];
    [alertControllerWifi addTextFieldWithConfigurationHandler:^(UITextField * textField) {
        
        eyeButton = [UIButton buttonWithType: UIButtonTypeCustom];
        eyeButton.clipsToBounds = TRUE;
        eyeButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 5);
        eyeButton.frame = CGRectMake(0, 0, 44, 44);
        [eyeButton setTintColor:UIColor.blackColor];
        [eyeButton setImage:[UIImage imageNamed:@"eye_hide.png"] forState:UIControlStateNormal];
        [eyeButton addTarget:self action:@selector(eyeButtonReleased:) forControlEvents:UIControlEventTouchUpInside];
        
        [textField setSecureTextEntry:YES];
        textField.placeholder = @"Password";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.secureTextEntry = YES;
        
        textField.rightView = eyeButton;
        textField.rightViewMode = UITextFieldViewModeWhileEditing;
        
        NSString * networkPassword = MTRGetDomainValueForKey(MTRToolDefaultsDomain, kNetworkPasswordDefaultsKey);
        if ([networkPassword length] > 0) {
            textField.text = networkPassword;
        }
    }];
    [alertControllerWifi addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
        [self refresh];
    }]];
    
    __weak typeof(self) weakSelf = self;
    [alertControllerWifi
     addAction:[UIAlertAction actionWithTitle:@"Send"
                                        style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction * action) {
        typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            NSArray * textfields = alertControllerWifi.textFields;
            UITextField * networkSSID = textfields[0];
            UITextField * networkPassword = textfields[1];
            if ([networkSSID.text length] > 0) {
                MTRSetDomainValueForKey(MTRToolDefaultsDomain, kNetworkSSIDDefaultsKey, networkSSID.text);
            }
            
            if ([networkPassword.text length] > 0) {
                MTRSetDomainValueForKey(MTRToolDefaultsDomain, kNetworkPasswordDefaultsKey, networkPassword.text);
            }
            //CHANGE...
            NSLog(@"New SSID: %@ Password: %@", networkSSID.text, networkPassword.text);
            
            //Commented for flow change...
            
            //[strongSelf commissionWithSSID:networkSSID.text password:networkPassword.text];
            
            //Add for flow change...
            ssidStr = networkSSID.text;
            passwordStr = networkPassword.text;
            [self postScanningQRCodeState];
            NSLog(@"you pressed No, thanks button");
            // call method whatever u need
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, INDICATOR_DELAY), dispatch_get_main_queue(), ^{
                [self displayQRCodeInSetupPayloadView:self->_setupPayload rawPayload:strQrCode error:error];
            });
        }
    }]];
    [self presentViewController:alertControllerWifi animated:YES completion:nil];
}

// Password show and hide action
- (void)eyeButtonReleased:(id)sender {
    UITextField * networkPassword = alertControllerWifi.textFields[1];
    if (passIsShow){
        networkPassword.secureTextEntry = YES;
        [eyeButton setImage:[UIImage imageNamed:@"eye_hide.png"] forState:UIControlStateNormal];
        passIsShow = FALSE;
    } else {
        networkPassword.secureTextEntry = NO;
        [eyeButton setImage:[UIImage imageNamed:@"eye_view.png"] forState:UIControlStateNormal];
        passIsShow = TRUE;
    }
}

// Retrieve And Send Thread Credentials
- (void)retrieveAndSendThreadCredentials:(NSString *)strQrCode error:(NSError *)error  {
    UITextView *inputTextView = [[UITextView alloc] initWithFrame:CGRectZero];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Thread Configuration"
                                                                             message:@"Enter OTBR dataset to connect. \n\n\n\n\n"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* send = [UIAlertAction actionWithTitle:@"Send" style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * action) {
        
        NSString *payloadStr = [inputTextView text];
        
        NSLog(@" payload Str :- %@", payloadStr);
        self.datasetValue = [self dataFromHexString: payloadStr];
        
        //Commented for flow change...
        
        //Commission With Thread using dataset
        //[self commissionWithThread:self.datasetValue];
        
        //Add for flow change...
        [self postScanningQRCodeState];
        // call method whatever u need
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, INDICATOR_DELAY), dispatch_get_main_queue(), ^{
            [self displayQRCodeInSetupPayloadView:self->_setupPayload rawPayload:strQrCode error:error];
        });
        
    }];
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
        [alertController dismissViewControllerAnimated:YES completion:nil];
        [self refresh];
    }];
    [alertController addAction:cancel];
    [alertController addAction:send];
    
    alertController.view.autoresizesSubviews = YES;
    inputTextView.translatesAutoresizingMaskIntoConstraints = NO;
    inputTextView.editable = YES;
    inputTextView.dataDetectorTypes = UIDataDetectorTypeAll;
    inputTextView.text = @"";
    inputTextView.userInteractionEnabled = YES;
    inputTextView.backgroundColor = [UIColor whiteColor];
    inputTextView.scrollEnabled = YES;
    inputTextView.layer.borderWidth = 1.0f;
    inputTextView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    inputTextView.layer.cornerRadius = 5;
    
    NSLayoutConstraint *leadConstraint = [NSLayoutConstraint constraintWithItem:alertController.view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:inputTextView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:-8.0];
    NSLayoutConstraint *trailConstraint = [NSLayoutConstraint constraintWithItem:alertController.view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:inputTextView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:8.0];
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:alertController.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:inputTextView attribute:NSLayoutAttributeTop multiplier:1.0 constant:-85.0];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:alertController.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:inputTextView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:55.0];
    [alertController.view addSubview:inputTextView];
    [NSLayoutConstraint activateConstraints:@[leadConstraint, trailConstraint, topConstraint, bottomConstraint]];
    
    [self presentViewController: alertController animated: YES completion: nil];
}

- (void)commissionWithSSID:(NSString *)ssid password:(NSString *)password {
    
    NSError * error;
    MTRDeviceController * controller = InitializeMTR();
    // create commissioning params in ObjC. Pass those in here with network credentials.
    // maybe this just becomes the new norm
    MTRCommissioningParameters * params = [[MTRCommissioningParameters alloc] init];
    params.wifiSSID = [ssid dataUsingEncoding:NSUTF8StringEncoding];
    params.wifiCredentials = [password dataUsingEncoding:NSUTF8StringEncoding];
    params.deviceAttestationDelegate = [[CHIPToolDeviceAttestationDelegate alloc] initWithViewController:self];
    params.failSafeExpiryTimeoutSecs = @600;
    
    uint64_t deviceId = MTRGetNextAvailableDeviceID() - 1;
    
    if (![controller commissionDevice:deviceId commissioningParams:params error:&error]) {
        NSLog(@"Failed to commission Device %llu, with error %@", deviceId, error);
    }
}

// Commission With Thread
- (void)commissionWithThread:(NSData *)dataSet {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus: @"Commissioning Device..."];
    });
    
    NSError * error;
    MTRDeviceController * controller = InitializeMTR();
    // create commissioning params in ObjC. Pass those in here with network credentials.
    // maybe this just becomes the new norm
    MTRCommissioningParameters * params = [[MTRCommissioningParameters alloc] init];
    params.threadOperationalDataset = dataSet;
    params.deviceAttestationDelegate = [[CHIPToolDeviceAttestationDelegate alloc] initWithViewController:self];
    params.failSafeExpiryTimeoutSecs = @6000;
    
    uint64_t deviceId = MTRGetNextAvailableDeviceID() - 1;
    
    if (![controller commissionDevice:deviceId commissioningParams:params error:&error]) {
        NSLog(@"Failed to commission Device %llu, with error %@", deviceId, error);
    }
}

// Change data from hex string
- (NSData *)dataFromHexString:(NSString *) string {
    if([string length] % 2 == 1){
        string = [@"0"stringByAppendingString: string];
    }
    
    const char *chars = [string UTF8String];
    int i = 0, len = (int)[string length];
    
    NSMutableData *data = [NSMutableData dataWithCapacity: len / 2];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    
    while (i < len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    return data;
}
- (void)refresh {
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        [self openCameraView];
    });
}
-(int64_t) getUniqueTimestamp {
    
    NSString * strTimeStamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
    NSString * stringFullTimeStamp = [strTimeStamp stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSLog(@"unique timestamp %@", stringFullTimeStamp);
    NSString *uniqueId = [stringFullTimeStamp substringFromIndex: [stringFullTimeStamp length] - 4];
    uint64_t uniqueTimestamp = uniqueId.intValue;
    NSLog(@"uniqueId last 8 digit - %llu", uniqueTimestamp);
    return uniqueTimestamp;
}
-(void) showAlertPopup:(NSString *) message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message: message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

// MARK: MTRDeviceControllerDelegate
- (void)controller:(MTRDeviceController *)controller commissioningComplete:(NSError * _Nullable)error nodeID:(NSNumber * _Nullable)nodeID {
    NSLog(@" nodeID ===:- %@", nodeID);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    });
    if (error != nil) {
        NSLog(@"Error retrieving device information over Mdns: %@", error);
        // Show popup
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertPopup:kDeviceRetrievingErrorMessage];
            [self refresh];
        });
        return;
    }
    
    // track this device
    MTRSetDevicePaired([nodeID unsignedLongLongValue], YES);
    [self setVendorIDOnAccessory];
    
    
    //saved_list
    MKdeviceListTemp = [[NSMutableArray alloc] init];
    //MKdeviceListTemp = [[[NSUserDefaults standardUserDefaults] valueForKey:@"saved_list"] mutableCopy];
    MKdeviceListTemp = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    NSLog(@" MKdeviceListTemp == %@\n", MKdeviceListTemp);
    [self saveDevice:nodeID];
    
}

// MARK: MTRDeviceControllerDelegate
- (void)controller:(MTRDeviceController *)controller readCommissioningInfo:(MTRProductIdentity *)info {
    NSLog(@"readCommissioningInfo, vendorID:%@, productID:%@", info.vendorID, info.productID);
    if (info.vendorID == 0 && info.productID == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [self showAlertPopup:kDeviceRetrievingErrorMessage];
            //[self.navigationController popViewControllerAnimated: YES];
            [self refresh];
        });
    }
}
- (void)controller:(MTRDeviceController *)controller statusUpdate:(MTRCommissioningStatus)status{
    NSLog(@"readCommissioningInfo: %ld", (long)status);
    NSLog(@"readCommissioningInfo: %@", controller.controllerNodeID);
    //NSLog(@"readCommissioningInfo: %@", controller.isRunning);
    //95719443806068932
    int deviceStatus = (int)status;
    if (deviceStatus == 2) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [self showAlertPopup:@"This device is already commissioned."];
            [self refresh];
        });
    }else if (deviceStatus == 0){
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [self showAlertPopup:@"Device commissioning status Unknown.  Please try again."];
            [self refresh];
        });
    }
}

- (void)parseOptionalData:(MTRSetupPayload *)payload {
    NSLog(@"Payload vendorID %@", payload.vendorID);
    BOOL isSameVendorID = [payload.vendorID isEqualToNumber:[NSNumber numberWithInt:EXAMPLE_VENDOR_ID]];
    if (!isSameVendorID) {
        return;
    }
    
    NSArray * optionalInfo = [payload getAllOptionalVendorData:nil];
    for (MTROptionalQRCodeInfo * info in optionalInfo) {
        NSNumber * tag = info.tag;
        if (!tag) {
            continue;
        }
        BOOL isTypeString = [info.infoType isEqualToNumber:[NSNumber numberWithInt:MTROptionalQRCodeInfoTypeString]];
        if (!isTypeString) {
            return;
        }
        NSString * infoValue = info.stringValue;
        switch (tag.unsignedCharValue) {
            case EXAMPLE_VENDOR_TAG_IP:
                if ([infoValue length] > MAX_IP_LEN) {
                    NSLog(@"Unexpected IP String... %@", infoValue);
                }
                break;
        }
    }
}

// MARK: Rendez Vous

- (void)handleRendezVous:(MTRSetupPayload *)payload rawPayload:(NSString *)rawPayload {
    if (payload.rendezvousInformation == nil) {
        NSLog(@"Rendezvous Default");
        [self handleRendezVousDefault:rawPayload];
        return;
    }
    
    // TODO: This is a pretty broken way to handle a bitmask.
    switch ([payload.rendezvousInformation unsignedLongValue]) {
        case MTRDiscoveryCapabilitiesNone:
        case MTRDiscoveryCapabilitiesOnNetwork:
        case MTRDiscoveryCapabilitiesBLE:
            //[self handleRendezVousDefault:rawPayload];
        case MTRDiscoveryCapabilitiesAllMask:
            NSLog(@"Rendezvous Default");
            [self handleRendezVousDefault:rawPayload];
            break;
        case MTRDiscoveryCapabilitiesSoftAP:
            NSLog(@"Rendezvous Wi-Fi");
            [self handleRendezVousWiFi:[self getNetworkName:payload.discriminator]];
            break;
    }
}

- (NSString *)getNetworkName:(NSNumber *)discriminator {
    NSString * peripheralDiscriminator = [NSString stringWithFormat:@"%04u", discriminator.unsignedShortValue];
    NSString * peripheralFullName = [NSString stringWithFormat:@"%@%@", NETWORK_CHIP_PREFIX, peripheralDiscriminator];
    return peripheralFullName;
}

- (void)_restartMatterStack {
    self.chipController = MTRRestartController(self.chipController);
    dispatch_queue_t callbackQueue = dispatch_queue_create("com.csa.matter.qrcodevc.callback", DISPATCH_QUEUE_SERIAL);
    [self.chipController setDeviceControllerDelegate:self queue:callbackQueue];
}

- (void)handleRendezVousDefault:(NSString *)payload {
    NSError * error;
    uint64_t deviceID = MTRGetNextAvailableDeviceID();
    
    // restart the Matter Stack before pairing (for reliability + testing restarts)
    [self _restartMatterStack];
    
    if ([self.chipController pairDevice:deviceID onboardingPayload:payload error:&error]) {
        deviceID++;
        MTRSetNextAvailableDeviceID(deviceID);
    }else{
        NSLog(@"EL");
    }
}

- (void)handleRendezVousWiFi:(NSString *)name {
    NSString * message = [NSString stringWithFormat:@"SSID: %@\n\nUse WiFi Settings to connect to it.", name];
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"SoftAP Detected"
                                                                    message:message
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

// MARK: QR Code

- (BOOL)startScanning {
    NSError * error;
    AVCaptureDevice * captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"Could not setup device input: %@", [error localizedDescription]);
        return NO;
    }
    
    AVCaptureMetadataOutput * captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession addInput:input];
    [_captureSession addOutput:captureMetadataOutput];
    
    if (!_captureSessionQueue) {
        _captureSessionQueue = dispatch_queue_create("captureSessionQueue", NULL);
    }
    
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:_captureSessionQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject: AVMetadataObjectTypeQRCode]];
    
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity: AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame: _qrView.layer.bounds];
    
    [_qrView.layer addSublayer:_videoPreviewLayer];
    
    [_captureSession startRunning];
    
    return YES;
}

- (void)displayQRCodeInSetupPayloadView:(MTRSetupPayload *)payload rawPayload:(NSString *)rawPayload error:(NSError *)error {
    if (error) {
        //[self showError:error];
        [self showAlertPopup:@"QR code is invalid!"];
        [self refresh];
    } else {
        [self showPayload:payload rawPayload:rawPayload isManualCode:NO];
    }
}

- (void)scannedQRCode:(NSString *)qrCode {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_captureSession stopRunning];
        [self->_session invalidateSession];
    });
    MTRQRCodeSetupPayloadParser * parser = [[MTRQRCodeSetupPayloadParser alloc] initWithBase38Representation:qrCode];
    NSError * error;
    _setupPayload = [parser populatePayload: &error];
    NSLog(@" _setupPayload:-  %@", _setupPayload);
    // Show QR code info in popup
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self showQRCodeInfo: self.setupPayload strQrCode: qrCode error: error];
    });
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject * metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            [self scannedQRCode:[metadataObj stringValue]];
        }
    }
}

// MARK: Manual Code
- (void)displayManualCodeInSetupPayloadView:(MTRSetupPayload *)payload decimalString:(NSString *)decimalString withError:(NSError *)error {
    [self->_activityIndicator stopAnimating];
    self->_activityIndicator.hidden = YES;
    [SVProgressHUD dismiss];
    
    if (error) {
        [self showError:error];
    } else {
        [self showPayload:payload rawPayload: decimalString isManualCode:YES];
    }
}

// MARK: IBActions

- (IBAction)cancelQRInfoPopup:(id)sender {
    _qrCodeInfoView.hidden = TRUE;
    [self refresh];
}

- (IBAction)qrCodeInfoOkAction:(id)sender {
    _qrCodeInfoView.hidden = TRUE;
    [self commissioningOption:savedStrQrCode error:savedError];
}

- (IBAction)addDeviceNameAction:(id)sender {
    // add device name
    NSString *trimmedTextFieldText = [self.nameInputTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (![trimmedTextFieldText  isEqual: @""]){
        [self deviceSaveInLocalDB:deviceTypeAfterCommission nodeId:nodeIdAfterCommision deviceTitle:self.nameInputTextField.text];
    }else{
        [self showAlertPopup:@"Please enter a device name."];
    }
}

- (IBAction)startScanningQRCode:(id)sender {
    [self scanningStartState];
    [self startScanning];
}

- (IBAction)stopScanningQRCode:(id)sender {
    [self qrCodeInitialState];
}

- (IBAction)resetView:(id)sender {
    // reset the view and remove any preferences that were stored from scanning the QRCode
    [self manualCodeInitialState];
    [self qrCodeInitialState];
}

- (IBAction)readFromLedgerApi:(id)sender {
    
    NSLog(@"Clicked readFromLedger...");
    //    _readFromLedgerButton.hidden = YES;
    [SVProgressHUD showWithStatus: @"Commissioning Device..."];
}

// Enter Manual Code.
- (IBAction)enteredManualCode:(id)sender {
    NSError * error;
    NSString * qrString = _manualQrCodeTextField.text;
    MTRQRCodeSetupPayloadParser * parser = [[MTRQRCodeSetupPayloadParser alloc] initWithBase38Representation:qrString];
    _setupPayload = [parser populatePayload: &error];
    if(_setupPayload == nil){
        [self showAlertPopup:@"Manual QR code payload ID is invalid! Please enter a valid QR code payload ID."];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self commissioningOption: qrString error: error];
        });
    }
}

- (void)getRequest:(NSString *)url vendorId:(NSString *)vendorId productId:(NSString *)productId {
    [SVProgressHUD showWithStatus: @"Commissioning Device..."];
    NSString * targetUrl = [NSString stringWithFormat:@"%@/%@/%@", url, vendorId, productId];
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:targetUrl]];
    
    [[[NSURLSession sharedSession]
      dataTaskWithRequest:request
      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString * myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Data received: %@", myString);
        self->_ledgerRespond = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        //        [self getRequestCallback];
    }] resume];
}

- (NSString *)encodeStringTo64:(NSArray *)fromArray {
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:fromArray options:NSJSONWritingWithoutEscapingSlashes error:nil];
    NSString * base64String = [jsonData base64EncodedStringWithOptions:kNilOptions];
    return base64String;
}

// Commissioning Option
- (void)commissioningOption:(NSString *)strQrCode error:(NSError *)error {
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"Commissioning"
                                                                  message:@"Select network mode"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* threadButton = [UIAlertAction actionWithTitle:@"Thread"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
        NSLog(@"you pressed Yes, please button");
        isThread = @"THREAD";
        [self retrieveAndSendThreadCredentials:strQrCode error:error];
    }];
    
    UIAlertAction* wifiButton = [UIAlertAction actionWithTitle:@"Wi-Fi"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action)
                                 {
        // CHANGE...
        // [self postScanningQRCodeState];
        NSLog(@"you pressed No, thanks button");
        // call method whatever u need
        isThread = @"WIFI";
        //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, INDICATOR_DELAY), dispatch_get_main_queue(), ^{
        //            [self displayQRCodeInSetupPayloadView:self->_setupPayload rawPayload:strQrCode error:error];
        //        });
        
        [self retrieveAndSendWiFiCredentials:strQrCode error:error];
    }];
    
    UIAlertAction* cancelButton = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
        NSLog(@"you pressed No, thanks button");
        [self refresh];
        // call method whatever u need
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alert addAction:wifiButton];
    [alert addAction:threadButton];
    [alert addAction:cancelButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deviceSaveInLocalDB:(NSNumber *)deviceTypeId nodeId:(NSNumber *)nodeid deviceTitle:(NSString *)deviceTitleValue{
    NSMutableDictionary * deviceDic = [[NSMutableDictionary alloc] init];
    [deviceDic setObject:deviceTypeId forKey:@"deviceType"];
    [deviceDic setObject:nodeid forKey:@"nodeId"];
    [deviceDic setObject:@1 forKey:@"endPoint"];
    [deviceDic setObject:@"1" forKey:@"isConnected"];
    [deviceDic setObject:deviceTitleValue forKey:@"title"];
    [MKdeviceListTemp addObject:deviceDic];
    [[NSUserDefaults standardUserDefaults] setObject:MKdeviceListTemp forKey:@"saved_list"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    dispatch_async(dispatch_get_main_queue(), ^{
        // Go back to with payload and add device
        self->_addDeviceNameView.hidden = TRUE;
        [self.navigationController popViewControllerAnimated: YES];
    });
}

// MARK: TextField Delegates

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    _baseViewTopConstraint.constant = -200;
    return true;
}

- (BOOL)resignFirstResponder {
    _baseViewTopConstraint.constant = 0;
    return true;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    _baseViewTopConstraint.constant = 0;
    return YES;
}

@synthesize description;

@end

@implementation CHIPToolDeviceAttestationDelegate

- (instancetype)initWithViewController:(QRCodeViewController *)viewController {
    if (self = [super init]) {
        _viewController = viewController;
    }
    return self;
}

- (void)deviceAttestation:(MTRDeviceController *)controller failedForDevice:(void *)device error:(NSError * _Nonnull)error {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController * alertController = [UIAlertController
                                               alertControllerWithTitle:@"Device Attestation"
                                               message:@"Device Attestation failed for device under commissioning. Do you wish to continue pairing?"
                                               preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"No"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
            NSError * err;
            [controller continueCommissioningDevice:device
                           ignoreAttestationFailure:NO
                                              error:&err];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"Continue"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
            NSError * err;
            [controller continueCommissioningDevice:device
                           ignoreAttestationFailure:YES
                                              error:&err];
        }]];
        
        [self.viewController presentViewController:alertController animated:YES completion:nil];
    });
}
@end

