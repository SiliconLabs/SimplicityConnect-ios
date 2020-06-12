//
//  SILBluetoothBrowserExpandableViewManager.h
//  SiliconLabsApp
//
//  Created by Kamil Czajka on 26/03/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#ifndef SILBluetoothBrowserExpandableViewManager_h
#define SILBluetoothBrowserExpandableViewManager_h

#import "SILBrowserLogViewController.h"
#import "SILBrowserConnectionsViewController.h"
#import "SILBrowserFilterViewController.h"

@interface SILBluetoothBrowserExpandableViewManager : NSObject

- (instancetype)initWithOwnerViewController:(UIViewController*)viewController;
- (void)setValueForCornerRadius:(CGFloat)cornerRadius;
- (void)setReferenceForPresentationView:(UIView*)presentationView andDiscoveredDevicesView:(UIView*)discoveredDevicesView;
- (void)setReferenceForExpandableControllerView:(UIView*)expandableControllerView andExpandableControllerHeight:(NSLayoutConstraint*)expandableControllerHeight;
- (void)setupButtonsTabBarWithLog:(UIButton*)logButton connections:(UIButton*)connectionsButton;
- (void)setupButtonsTabBarWithLog:(UIButton*)logButton connections:(UIButton*)connectionsButton filter:(UIButton*)filterButton andFilterIsActive:(BOOL)isActive;
- (SILBrowserLogViewController*)logButtonWasTappedAction;
- (SILBrowserConnectionsViewController*)connectionsButtonWasTappedAction;
- (SILBrowserFilterViewController*)filterButtonWasTappedAction;
- (void)removeExpandingControllerIfNeeded;
- (void)updateConnectionsButtonTitle:(NSUInteger)connections;
- (void)updateFilterIsActiveFilter:(BOOL)isActiveFilter;

@end

#endif /* SILBluetoothBrowserExpandableViewManager_h */
