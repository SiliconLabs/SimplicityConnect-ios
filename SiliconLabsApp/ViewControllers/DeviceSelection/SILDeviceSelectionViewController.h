//
//  SILDeviceSelectionViewController.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/13/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SILCentralManager;
@class CBPeripheral;
@class SILApp;
@protocol SILDeviceSelectionViewControllerDelegate;

@interface SILDeviceSelectionViewController : UIViewController

@property (weak, nonatomic) id<SILDeviceSelectionViewControllerDelegate> delegate;
@property (strong, nonatomic) SILCentralManager *centralManager;
@property (strong, nonatomic) SILApp *app;

@end

@protocol SILDeviceSelectionViewControllerDelegate <NSObject>

- (void)deviceSelectionViewController:(SILDeviceSelectionViewController *)viewController didSelectPeripheral:(CBPeripheral *)peripheral;

@optional
- (void)didDismissDeviceSelectionViewController;

@end