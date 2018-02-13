//
//  SILActivityBarViewController.h
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 2/10/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SILActivityBarState) {
    SILActivityBarStateResting,
    SILActivityBarStateScanning,
    SILActivityBarStateConnecting
};

@protocol SILActivityBarViewControllerDelegate;

@interface SILActivityBarViewController : UIViewController

@property (weak, nonatomic) id<SILActivityBarViewControllerDelegate> delegate;
@property (nonatomic) BOOL allowsStopActivity;

- (void)scanningAnimationWithMessage:(NSString *)message;
- (void)connectingAnimationWithMessage:(NSString *)message;
- (void)configureActivityBarWithState:(SILActivityBarState)state;
@end

@protocol SILActivityBarViewControllerDelegate <NSObject>
@optional
- (void)activityBarViewControllerDidTapActivityButton:(SILActivityBarViewController *)controller;
- (void)activityBarViewControllerDidTapStopActivityButton:(SILActivityBarViewController *)controller;
@end
