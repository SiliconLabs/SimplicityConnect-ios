//
//  SILConnectedLightingViewController.h
//  SiliconLabsApp
//
//  Created by jamaal.sedayao on 10/31/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SILCentralManager;
@class CBPeripheral;

@interface SILConnectedLightingViewController : UIViewController

@property (strong, nonatomic) SILCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *connectedPeripheral;

@end
