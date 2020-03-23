//
//  SILOTAUICoordinator.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/9/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILOTAUICoordinator.h"
#import "SILOTAFirmwareUpdateManager.h"
#import "CBPeripheral+Services.h"
#import "WYPopoverController+SILHelpers.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "SILOTASetupViewController.h"
#import "NSError+SILHelpers.h"
#import "SILOTAFirmwareUpdate.h"
#import "SILOTAFirmwareFile.h"
#import "SILPopoverViewController.h"
#import "SILOTAProgressViewController.h"

static NSString * const kSILDFUStatusRebootingString = @"Rebooting...";
static NSString * const kSILDFUStatusWaitingString = @"Waiting...";
static NSString * const kSILDFUStatusConnectingString = @"Attempting Connection...";
static NSString * const kSILOKButtonTitle = @"OK";
static NSString * const kSILFirmwareUpdateUnknownErrorTitle = @"Error";
static NSString * const kSILFirmwareUpdateBGErrorMessageFormat = @"Code 0x%lx: %@";
static NSString * const kSILFirmwareUpdateBGErrSecurityImageChecksumError = @"Image checksum error";
static NSString * const kSILFirmwareUpdateBGErrWrongState = @"Wrong state";
static NSString * const kSILFirmwareUpdateBGErrBuffersFull = @"Buffers full";
static NSString * const kSILFirmwareUpdateBGErrCommandTooLong = @"Command too long";
static NSString * const kSILFirmwareUpdateBGErrInvalidFileFormat = @"Invalid file format";
static NSString * const kSILFirmwareUpdateBGErrUnspecified = @"Unspecified error";
static NSString * const kSILFirmwareUpdateBGErrUnknown = @"Unspecified error";
static NSString * const kSILDeviceInOTAModeName = @"OTA";

@interface SILOTAUICoordinator () <SILOTASetupViewControllerDelegate, SILOTAProgressViewControllerDelegate,
SILOTAFirmwareUpdateManagerDelegate>

@property (weak, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) SILOTAFirmwareUpdateManager *otaFirmwareUpdateManager;
@property (weak, nonatomic) UIViewController *presentingViewController;
@property (strong, nonatomic) SILOTASetupViewController *setupViewController;
@property (strong, nonatomic) SILOTAProgressViewController *progressViewController;
@property (strong, nonatomic) SILOTAProgressViewModel *progressViewModel;
@property (strong, nonatomic) SILPopoverViewController *popoverViewController;
@property (strong, nonatomic) SILCentralManager *silCentralManager;

@property (weak, nonatomic) HMAccessory *accessory;

@property (nonatomic) SILOTAMode otaMode;

@end

@implementation SILOTAUICoordinator

#pragma mark - Initializers

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                    centralManager:(SILCentralManager *)centralManager
          presentingViewController:(UIViewController *)presentingViewController {
    self = [super init];
    if (self) {
        self.peripheral = peripheral;
        self.otaFirmwareUpdateManager = [[SILOTAFirmwareUpdateManager alloc] initWithPeripheral:self.peripheral
                                                                                centralManager:centralManager];
        self.otaFirmwareUpdateManager.delegate = self;
        self.presentingViewController = presentingViewController;
        self.otaMode = SILOTAModeReliability;
        self.silCentralManager = centralManager;
    }
    return self;
}

- (instancetype)initWithAccessory:(HMAccessory *)accessory
                       peripheral:(CBPeripheral *)peripheral
                   centralManager:(SILCentralManager *)centralManager
         presentingViewController:(UIViewController *)presentingViewController {
    self = [super init];
    if (self) {
        _accessory = accessory;
        _peripheral = peripheral;
        _otaFirmwareUpdateManager = [[SILOTAFirmwareUpdateManager alloc] initWithAccessory:_accessory
                                                                                peripheral:_peripheral
                                                                            centralManager:centralManager];
        _otaFirmwareUpdateManager.delegate = self;
        _presentingViewController = presentingViewController;
        _otaMode = SILOTAModeReliability;
        _silCentralManager = centralManager;
    }
    return self;
}

#pragma mark - Public

- (void)initiateOTAFlow {
    if ([self.peripheral hasOTAService]) {
        [self presentOTASetup];
    } else {
        [self.delegate otaUICoordinatorDidFishishOTAFlow:self];
    }
}

#pragma mark - Helpers

- (void)presentOTASetup {
    self.setupViewController = [[SILOTASetupViewController alloc] initWithPeripheral:_peripheral withCentralManager:_otaFirmwareUpdateManager.centralManager];
    self.setupViewController.delegate = self;
    self.popoverViewController = [[SILPopoverViewController alloc] initWithNibName:nil bundle:nil contentViewController:self.setupViewController];
    [self.presentingViewController presentViewController:self.popoverViewController animated:YES completion:nil];
}


- (void)showOTAProgressForFirmwareFile:(SILOTAFirmwareFile *)file ofType:(NSString *)type outOf:(NSInteger)totalNumber withCompletion:(void (^ __nullable)(void))completion {
    [self dismissPopoverWithCompletion:^{
        [self presentOTAProgressWithCompletion:^{
            self.progressViewModel.totalNumberOfFiles = totalNumber;
            self.progressViewModel.file = file;
            self.progressViewModel.uploadType = type;
            self.progressViewModel.uploadingFile = YES;
            if (completion) {
                completion();
            }
        }];
    }];
}

- (void)presentOTAProgressWithCompletion:(void (^ __nullable)(void))completion {
    self.progressViewModel = [[SILOTAProgressViewModel alloc] initWithPeripheral:_peripheral withCentralManager:_otaFirmwareUpdateManager.centralManager];
    self.progressViewController = [[SILOTAProgressViewController alloc] initWithViewModel: self.progressViewModel];
    self.progressViewController.delegate = self;
    self.popoverViewController = [[SILPopoverViewController alloc] initWithNibName:nil bundle:nil contentViewController:self.progressViewController];
    [self.presentingViewController presentViewController:self.popoverViewController animated:YES completion:completion];
}

- (void)dismissPopoverWithCompletion:(void (^ __nullable)(void))completion {
    [self.popoverViewController dismissViewControllerAnimated:YES completion:completion];
}

- (NSString *)stringForDFUStatus:(SILDFUStatus)status {
    NSString *statusString;
    switch (status) {
        case SILDFUStatusRebooting:
            statusString = kSILDFUStatusRebootingString;
            break;
        case SILDFUStatusWaiting:
            statusString = kSILDFUStatusWaitingString;
            break;
        case SILDFUStatusConnecting:
            statusString = kSILDFUStatusConnectingString;
            break;
        default:
            break;
    }
    return statusString;
}

- (void)presentAlertControllerWithError:(NSError *)error animated:(BOOL)animated {
    NSString *title;
    NSString *message;

    NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
    NSString *underlyingSILErrorMessage = [self underlyingSILErrorMessageForError:error withUnderlyingError:underlyingError];

    if (underlyingSILErrorMessage) {
        title = kSILFirmwareUpdateUnknownErrorTitle;
        message = underlyingSILErrorMessage;

    } else {
        title = (underlyingError == nil) ? error.localizedDescription : underlyingError.localizedDescription;
        message = (underlyingError == nil) ? error.localizedRecoverySuggestion : underlyingError.localizedRecoverySuggestion;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *action = [self alertActionForError:error];
    [alert addAction:action];
    [self.presentingViewController presentViewController:alert animated:animated completion:nil];
}

- (NSString *)underlyingSILErrorMessageForError:(NSError *)error withUnderlyingError:(NSError *)underlyingError {
    NSString *message;
    if (error && underlyingError && error.code == 9) {
        switch (underlyingError.code) {
            case 0x80:
                message = kSILFirmwareUpdateBGErrSecurityImageChecksumError;
                break;
            case 0x81:
                message = kSILFirmwareUpdateBGErrWrongState;
                break;
            case 0x82:
                message = kSILFirmwareUpdateBGErrBuffersFull;
                break;
            case 0x83:
                message = kSILFirmwareUpdateBGErrCommandTooLong;
                break;
            case 0x84:
                message = kSILFirmwareUpdateBGErrInvalidFileFormat;
                break;
            case 0x85:
                message = kSILFirmwareUpdateBGErrUnspecified;
                break;
            default:
                message = kSILFirmwareUpdateBGErrUnknown;
                break;
        }
        return [NSString stringWithFormat:kSILFirmwareUpdateBGErrorMessageFormat, (long)underlyingError.code, message];
    }
    return NULL;
}

- (UIAlertAction *)alertActionForError:(NSError *)error {
    void (^ __nullable handler)(UIAlertAction *);
    if (error.code == SILErrorCodeOTAFailedToConnectToPeripheral || error.code == SILErrorCodeOTADisconnectedFromPeripheral) {
        handler = ^void(UIAlertAction * handler) {
            [self.delegate otaUICoordinatorDidFishishOTAFlow:self];
        };
    }
    return [UIAlertAction actionWithTitle:kSILOKButtonTitle
                                    style:UIAlertActionStyleDefault
                                  handler:handler];
}

#pragma mark - SILOTASetupViewControllerDelegate

- (void)otaSetupViewControllerEnterDFUModeForFirmwareUpdate:(SILOTAFirmwareUpdate *)firmwareUpdate {
    [SVProgressHUD show];
    
    self.otaMode = firmwareUpdate.updateMode;
    __weak SILOTAUICoordinator *weakSelf = self;
    [self reupdateDeviceInOtaMode];
    [self.otaFirmwareUpdateManager cycleDeviceWithInitiationByteSequence:YES
                                                                progress:^(SILDFUStatus status) {
                                                                    [SVProgressHUD setStatus:[weakSelf stringForDFUStatus:status]];
                                                                } completion:^(CBPeripheral *peripheral, NSError *error) {
                                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                                         [SVProgressHUD dismiss];
                                                                         if (error == nil) {
                                                                             weakSelf.peripheral = peripheral;
                                                                             [weakSelf otaSetupViewControllerDidInitiateFirmwareUpdate:firmwareUpdate];
                                                                         } else {
                                                                             [weakSelf dismissPopoverWithCompletion:^{
                                                                                 [weakSelf presentAlertControllerWithError:error animated:YES];
                                                                             }];
                                                                         }
                                                                     });
                                                                }];
}

- (void)reupdateDeviceInOtaMode {
    if ([self.peripheral.name isEqualToString:kSILDeviceInOTAModeName]) {
         [self.otaFirmwareUpdateManager disconnectConnectedPeripheral];
     }
}

- (void)otaSetupViewControllerDidCancel:(SILOTASetupViewController *)controller {
    if ([self.delegate respondsToSelector:@selector(otaUICoordinatorDidCancelOTAFlow:)]) {
        [self.delegate otaUICoordinatorDidCancelOTAFlow:self];
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)otaSetupViewControllerDidInitiateFirmwareUpdate:(SILOTAFirmwareUpdate *)firmwareUpdate {
    const BOOL isFullUpdate = firmwareUpdate.updateMethod == SILOTAMethodFull;
    const BOOL isPartialUpdate = firmwareUpdate.updateMethod == SILOTAMethodPartial;
    
    if (!(isFullUpdate || isPartialUpdate)) {
        return;
    }
    
    __weak SILOTAUICoordinator * const weakSelf = self;
    SILOTAFirmwareFile * const firmwareFile = isFullUpdate ? firmwareUpdate.stackFile : firmwareUpdate.appFile;
    NSString * const firmwareFileType = isFullUpdate ? @"STACK" : @"APP";
    const int numberOfFilesToUpload = isFullUpdate ? 2 : 1;
    void (^const uploadFileCompletion)(CBPeripheral *peripheral, NSError *error) = ^(CBPeripheral *peripheral, NSError *error) {
        if (isFullUpdate) {
            [weakSelf handleStackFileUploadCompletionForPeripheral:peripheral error:error withFirmwareUpdate:firmwareUpdate];
        } else if (isPartialUpdate) {
            [weakSelf handleAppFileUploadCompletionForPeripheral:peripheral error:error];
        }
    };
    
    [self showOTAProgressForFirmwareFile:firmwareFile ofType:firmwareFileType outOf:numberOfFilesToUpload withCompletion:^{
        [weakSelf.otaFirmwareUpdateManager uploadFile:firmwareFile
                                             progress:^(NSInteger bytes, double fraction) {
                                                 [weakSelf handleFileUploadProgress:fraction uploadedBytes:bytes];
                                             }
                                           completion:uploadFileCompletion];
    }];
}

- (void)handleError:(NSError *)error {
    [self dismissPopoverWithCompletion:^{
        [self presentAlertControllerWithError:error animated:YES];
    }];
}

- (void)handleFileUploadProgress:(double)progress uploadedBytes:(NSInteger)bytes {
    self.progressViewModel.progressFraction = (CGFloat)progress;
    self.progressViewModel.progressBytes = bytes;
}

- (void)handleCycleDeviceProgress:(SILDFUStatus)status {
    self.progressViewModel.uploadingFile = NO;
    self.progressViewModel.statusString = [self stringForDFUStatus:status];
}

- (void)handleCycleDeviceCompletionForPeripheral:(CBPeripheral *)peripheral error:(NSError *)error withFirmwareUpdate:(SILOTAFirmwareUpdate *)firmwareUpdate {
    __weak SILOTAUICoordinator *weakSelf = self;
    
    if (error != nil) {
        [self handleError:error];
        return;
    }
    
    self.progressViewModel.file = firmwareUpdate.appFile;
    self.progressViewModel.uploadType = @"APP";
    self.progressViewModel.uploadingFile = YES;
    [self.otaFirmwareUpdateManager uploadFile:firmwareUpdate.appFile
                                     progress:^(NSInteger bytes, double fraction) {
                                                [weakSelf handleFileUploadProgress:fraction uploadedBytes:bytes];
                                              }
                                   completion:^(CBPeripheral *peripheral, NSError *error) {
                                                [weakSelf handleAppFileUploadCompletionForPeripheral:peripheral error:error];
                                              }];
}

- (void)handleStackFileUploadCompletionForPeripheral:(CBPeripheral *)peripheral error:(NSError *)error withFirmwareUpdate:(SILOTAFirmwareUpdate *)firmwareUpdate {
    __weak SILOTAUICoordinator *weakSelf = self;
    
    if (error != nil) {
        [self handleError:error];
        return;
    }
    
    [self.otaFirmwareUpdateManager cycleDeviceWithInitiationByteSequence:NO
                                                                progress:^(SILDFUStatus status) {
                                                                    [weakSelf handleCycleDeviceProgress:status];
                                                                }
                                                              completion:^(CBPeripheral *peripheral, NSError *error) {
                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                        [weakSelf handleCycleDeviceCompletionForPeripheral:peripheral error:error withFirmwareUpdate:firmwareUpdate];
                                                                    });
                                                                }];
}

- (void)handleAppFileUploadCompletionForPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    self.progressViewModel.uploadingFile = NO;
    
    if (error == nil) {
        self.progressViewModel.finished = YES;
    } else {
        [self dismissPopoverWithCompletion:^{
            [self presentAlertControllerWithError:error animated:YES];
        }];
    }
}

#pragma mark - SILOTAProgressViewControllerDelegate

- (void)progressViewControllerDidPressDoneButton:(SILOTAProgressViewController *)controller {
    [self dismissPopoverWithCompletion:^{
        [self.delegate otaUICoordinatorDidFishishOTAFlow:self];
        [self.silCentralManager disconnectFromPeripheral:self.peripheral];
    }];
}

#pragma mark - SILOTAFirmwareUpdateManagerDelegate 

- (CBCharacteristicWriteType)characteristicWriteType {
    return self.otaMode == SILOTAModeReliability ? CBCharacteristicWriteWithResponse : CBCharacteristicWriteWithoutResponse;
}

- (void)firmwareUpdateManagerDidUnexpectedlyDisconnectFromPeripheral:(SILOTAFirmwareUpdateManager *)firmwareUpdateManager
                                                           withError:(NSError *)error {
    [self dismissPopoverWithCompletion:^{
        [self presentAlertControllerWithError:error animated:YES];
    }];
}

@end
