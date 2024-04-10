

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <CoreNFC/CoreNFC.h>
#import <Matter/Matter.h>
#import <UIKit/UIKit.h>

@protocol QRCodeViewControllerDelegate <NSObject>
- (void) affterCommission:(NSNumber *_Nullable)nodeId;
@end

@interface QRCodeViewController: UIViewController <AVCaptureMetadataOutputObjectsDelegate, MTRDeviceControllerDelegate, NFCNDEFReaderSessionDelegate, UITextFieldDelegate>
@property (nonatomic, retain) id <QRCodeViewControllerDelegate> _Nullable delegate;
@property (weak, nonatomic) IBOutlet UIView * _Nullable qrView;
@property (weak, nonatomic) IBOutlet UITextField * _Nullable manualQrCodeTextField;
@property (weak, nonatomic) IBOutlet UIButton * _Nullable pairButton;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable hintLbl;
@property (weak, nonatomic) IBOutlet UIView * _Nullable addDeviceNameView;
@property (weak, nonatomic) IBOutlet UIView * _Nullable addDeviceNamePopupView;
@property (weak, nonatomic) IBOutlet UITextField * _Nullable nameInputTextField;
@property (weak, nonatomic) IBOutlet UIButton * _Nullable addDeviceButton;

@property (weak, nonatomic) IBOutlet UIView * _Nullable qrCodeInfoView;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable qrCodeInfoLabel;
@property (weak, nonatomic) IBOutlet UIButton * _Nullable qrCodeInfoButton;
@property (weak, nonatomic) IBOutlet UIView * _Nullable qrCodeInfoBGView;

@property (weak, nonatomic) IBOutlet UILabel * _Nullable versionLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable vendorIdLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable productIdLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable discriminatorLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable setupPinCodeLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable discoveryCapabilitiesLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable commissioningFlow;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end
