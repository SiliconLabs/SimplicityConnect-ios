//
//  SILAppSelectionHelpViewController.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/26/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol SILAppSelectionHelpViewControllerDelegate;

@interface SILAppSelectionHelpViewController : UIViewController

@property (weak, nonatomic) id<SILAppSelectionHelpViewControllerDelegate> delegate;

@end


@protocol SILAppSelectionHelpViewControllerDelegate <NSObject>

- (void)didFinishHelpWithAppSelectionHelpViewController:(SILAppSelectionHelpViewController *)helpViewController;

@end