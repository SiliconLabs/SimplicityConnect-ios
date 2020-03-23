//
//  SILOTASetupViewController.h
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/10/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILOTAHUDPeripheralViewModel.h"
#import "CBPeripheral+Services.h"
#import "SILCentralManager.h"
#import "SILPopoverViewController.h"


@class SILOTAFirmwareUpdate;

@protocol SILOTASetupViewControllerDelegate;

@interface SILOTASetupViewController : UIViewController <SILPopoverViewControllerSizeConstraints>

@property (weak, nonatomic) id<SILOTASetupViewControllerDelegate> delegate;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral withCentralManager:(SILCentralManager *)centralManager;

@end

@protocol SILOTASetupViewControllerDelegate <NSObject>

- (void)otaSetupViewControllerDidCancel:(SILOTASetupViewController *)controller;
- (void)otaSetupViewControllerDidInitiateFirmwareUpdate:(SILOTAFirmwareUpdate *)firmwareUpdate;
- (void)otaSetupViewControllerEnterDFUModeForFirmwareUpdate:(SILOTAFirmwareUpdate *)firmwareUpdate ;

@end
