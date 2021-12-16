//
//  SILAppSelectionHelpviewController.h
//  SiliconLabsApp
//
//  Created by Anastazja Gradowska on 28/09/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

#ifndef SILAppSelectionHelpviewController_h
#define SILAppSelectionHelpviewController_h


#endif /* SILAppSelectionHelpviewController_h */

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

