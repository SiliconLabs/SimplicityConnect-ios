//
//  SILAppSelectionInfoViewController.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/26/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol SILAppSelectionInfoViewControllerDelegate;

@interface SILAppSelectionInfoViewController : UIViewController

@property (weak, nonatomic) id<SILAppSelectionInfoViewControllerDelegate> delegate;

@end


@protocol SILAppSelectionInfoViewControllerDelegate <NSObject>

- (void)didFinishInfoWithAppSelectionInfoViewController:(SILAppSelectionInfoViewController *)infoViewController;

@end
