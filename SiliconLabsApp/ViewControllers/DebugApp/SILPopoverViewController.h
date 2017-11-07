//
//  SILPopoverViewController.h
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/15/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SILPopoverViewControllerSizeConstraints;

@interface SILPopoverViewController : UIViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil contentViewController:(UIViewController *)contentViewController;

@end

@protocol SILPopoverViewControllerSizeConstraints <NSObject>
@optional
- (CGSize)popoverIPhoneSize;
- (CGSize)popoverIPadSize;
@end
