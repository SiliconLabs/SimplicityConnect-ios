//
//  SILHomeKitDebugServicesViewController.h
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/17/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HMAccessory, SILHomeKitManager;

@interface SILHomeKitDebugServicesViewController : UIViewController
@property (strong, nonatomic) HMAccessory *accessory;
@property (strong, nonatomic) SILHomeKitManager *homekitManager;
@end
