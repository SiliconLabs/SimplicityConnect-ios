//
//  WYPopoverController+SILHelpers.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/22/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "WYPopoverController.h"

@interface WYPopoverController (SILHelpers)

+ (WYPopoverController *)sil_presentCenterPopoverWithContentViewController:(UIViewController *)contentViewController
                                                  presentingViewController:(UIViewController *)presentingViewController
                                                                  delegate:(id<WYPopoverControllerDelegate>)delegate
                                                                  animated:(BOOL)animated;

@end
