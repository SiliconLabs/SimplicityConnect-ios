//
//  SILDeviceServicesViewController.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/2/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CBPeripheral, SILCentralManager;

@interface SILDebugServicesViewController : UIViewController
@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) SILCentralManager *centralManager;
@property (nonatomic, assign) IBInspectable CGFloat cornerRadius;

@property (weak, nonatomic) IBOutlet UIButton *disconnectButton;

@end
