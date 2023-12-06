

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <CoreNFC/CoreNFC.h>
#import <Matter/Matter.h>
#import <UIKit/UIKit.h>

@protocol QRCodeViewControllerDelegate <NSObject>
- (void) affterCommission:(NSNumber *_Nullable)nodeId;
@end

@interface QRCodeViewController: UIViewController <AVCaptureMetadataOutputObjectsDelegate, MTRDeviceControllerDelegate, NFCNDEFReaderSessionDelegate, UITextFieldDelegate>
@property (nonatomic, retain) id <QRCodeViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIView * qrView;
@property (weak, nonatomic) IBOutlet UITextField * manualQrCodeTextField;
@property (weak, nonatomic) IBOutlet UIButton * pairButton;
@property (weak, nonatomic) IBOutlet UILabel *hintLbl;
@property (weak, nonatomic) IBOutlet UIView *addDeviceNameView;
@property (weak, nonatomic) IBOutlet UIView *addDeviceNamePopupView;
@property (weak, nonatomic) IBOutlet UITextField *nameInputTextField;
@property (weak, nonatomic) IBOutlet UIButton *addDeviceButton;

@end
