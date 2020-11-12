//
//  SILExitPopupViewController.h
//  SiliconLabsApp
//
//  Created by Grzegorz Janosz on 17/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SILExitPopupViewControllerDelegate;

@interface SILExitPopupViewController: UIViewController

@property (weak, nonatomic) id<SILExitPopupViewControllerDelegate> delegate;

@end

@protocol SILExitPopupViewControllerDelegate <NSObject>

- (void)okWasTappedInExitPopupWithSwitchState:(BOOL)state;
- (void)cancelWasTappedInExitPopup;

@end

NS_ASSUME_NONNULL_END
