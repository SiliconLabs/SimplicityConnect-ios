//
//  UIViewController+Containment.h
//  Chronability
//
//  Created by Ying Quan Tan on 5/7/15.
//  Copyright (c) 2015 IntrepidPursuits. All rights reserved.
//

@import UIKit;

@interface UIViewController(Containment)

/*!
 *  Add a child view controller's view to the caller's view
 *
 *  @param controller the controller to add as a subview
 */
- (void)ip_addChildViewController:(UIViewController *)controller;

/*!
 *  Add a child view controller to the caller, but add the view to the specified subview
 *
 *  @param controller the controller to add as a subview
 *  @param view       the view with which to add the controller's view
 */
- (void)ip_addChildViewController:(UIViewController *)controller toView:(UIView *)view;

/*!
 *  Remove from parent
 */
- (void)ip_removeFromParentViewController;

@end
