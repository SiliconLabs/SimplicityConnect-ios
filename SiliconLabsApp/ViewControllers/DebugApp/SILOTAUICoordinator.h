//
//  SILOTAUICoordinator.h
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/9/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class HMAccessory;
@class SILCentralManager;

@protocol SILOTAUICoordinatorDelegate;

@interface SILOTAUICoordinator : NSObject

@property (weak, nonatomic) id<SILOTAUICoordinatorDelegate> delegate;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                    centralManager:(SILCentralManager *)centralManager
          presentingViewController:(UIViewController *)presentingViewController;

- (instancetype)initWithAccessory:(HMAccessory *)accessory
                       peripheral:(CBPeripheral *)peripheral
                   centralManager:(SILCentralManager *)centralManager
         presentingViewController:(UIViewController *)presentingViewController;

- (void)initiateOTAFlow;


@end

@protocol SILOTAUICoordinatorDelegate <NSObject>

@optional
- (void)otaUICoordinatorDidCancelOTAFlow:(SILOTAUICoordinator *)coordinator;
@required
- (void)otaUICoordinatorDidFishishOTAFlow:(SILOTAUICoordinator *)coordinator;

@end
