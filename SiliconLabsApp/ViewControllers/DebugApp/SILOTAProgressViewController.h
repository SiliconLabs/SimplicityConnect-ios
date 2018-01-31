//
//  SILOTAProgressViewController.h
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/15/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILOTAProgressViewModel.h"
#import "SILOTAHUDPeripheralViewModel.h"
#import "SILPopoverViewController.h"

@protocol SILOTAProgressViewControllerDelegate;

@interface SILOTAProgressViewController : UIViewController <SILPopoverViewControllerSizeConstraints>

@property (weak, nonatomic) id<SILOTAProgressViewControllerDelegate> delegate;

- (instancetype)initWithViewModel:(SILOTAProgressViewModel *)viewModel;

@end

@protocol SILOTAProgressViewControllerDelegate <NSObject>

- (void)progressViewControllerDidPressDoneButton:(SILOTAProgressViewController *)controller;

@end
