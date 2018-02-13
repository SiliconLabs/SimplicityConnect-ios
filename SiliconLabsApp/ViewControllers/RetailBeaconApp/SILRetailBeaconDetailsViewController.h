//
//  SILRetailBeaconDetailsViewController.h
//  SiliconLabsApp
//
//  Created by Max Litteral on 6/22/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SILBeaconRegistryEntryViewModel;
@protocol SILRetailBeaconDetailsViewControllerDelegate;

@interface SILRetailBeaconDetailsViewController : UIViewController

@property (weak, nonatomic) id<SILRetailBeaconDetailsViewControllerDelegate> delegate;
@property (strong, nonatomic) SILBeaconRegistryEntryViewModel *entryViewModel;

@end

@protocol SILRetailBeaconDetailsViewControllerDelegate <NSObject>

- (void)didFinishHelpWithBeaconDetailsViewController:(SILRetailBeaconDetailsViewController *)beaconDetailsViewController;

@end
