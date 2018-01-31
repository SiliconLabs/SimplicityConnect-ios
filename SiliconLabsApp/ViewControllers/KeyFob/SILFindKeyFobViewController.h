//
//  SILFindKeyFobViewController.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/4/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SILCentralManager;
@class CBPeripheral;

@interface SILFindKeyFobViewController : UIViewController

@property (strong, nonatomic) SILCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *keyFobPeripheral;
@property (strong, nonatomic) NSNumber *txPower;
@property (strong, nonatomic) NSNumber *lastRSSIMeasurement;

@end
