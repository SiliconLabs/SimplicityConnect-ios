//
//  SILHealthThermometerAppViewController.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/15/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SILCentralManager;
@class SILApp;
@class CBPeripheral;

@interface SILHealthThermometerAppViewController : UIViewController

@property (strong, nonatomic) SILCentralManager *centralManager;
@property (strong, nonatomic) SILApp *app;
@property (strong, nonatomic) CBPeripheral *connectedPeripheral;

@end

