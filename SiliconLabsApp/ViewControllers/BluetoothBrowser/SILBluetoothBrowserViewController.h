//
//  SILBluetoothBrowserViewController.h
//  BlueGecko
//
//  Created by Kamil Czajka on 30/12/2019.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

IB_DESIGNABLE
@interface SILBluetoothBrowserViewController : UIViewController

@property (nonatomic, assign) IBInspectable CGFloat cornerRadius;
@property BOOL filterIsSelected;

- (void)startScanning;
- (void)stopScanningAction;
- (void)startScanningAction;
- (void)filterButtonTapped;
- (void)sortButtonTapped;
- (void)mapButtonTapped;
- (void)setupFloatingButtonSettings:(id)settings;
- (IBAction)scanningButtonWasTapped:(id)sender;

@end

NS_ASSUME_NONNULL_END
