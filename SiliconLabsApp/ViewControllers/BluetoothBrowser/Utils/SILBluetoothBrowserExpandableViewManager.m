//
//  SILBluetoothBrowserExpandableViewManager.m
//  BlueGecko
//
//  Created by Kamil Czajka on 26/03/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SILBluetoothBrowserExpandableViewManager.h"
#import "UIImage+SILImages.h"
#import "SILStoryboard+Constants.h"
#import "SILBrowserLogViewController.h"
#import "SILBrowserConnectionsViewController.h"
#import "SILBrowserFilterViewController.h"
#import "SILBluetoothBrowser+Constants.h"

@interface SILBluetoothBrowserExpandableViewManager ()

@property (strong, nonatomic) UIButton* logButton;
@property (strong, nonatomic) UIButton* connectionsButton;
@property (strong, nonatomic) UIButton* filterButton;
@property (strong, nonatomic) UIImageView* activeFilterImageView;
@property (strong, nonatomic) NSLayoutConstraint* expandableControllerHeight;
@property (strong, nonatomic) UIView* expandableControllerView;
@property (strong, nonatomic) UIViewController* expandingViewController;
@property (strong, nonatomic) UIVisualEffectView* effectView;
@property (strong, nonatomic) UIView* presentationView;
@property (strong, nonatomic) UIView* discoveredDevicesView;
@property (strong, nonatomic) UIViewController* browserViewController;
@property (nonatomic, assign) CGFloat cornerRadius;

@end

@implementation SILBluetoothBrowserExpandableViewManager

- (instancetype)initWithOwnerViewController:(UIViewController*)viewController {
    self = [super init];
    if (self) {
        _browserViewController = viewController;
        _cornerRadius = 0;
    }
    return self;
}

- (void)setupButtonsTabBarWithLog:(UIButton*)logButton connections:(UIButton*)connectionsButton {
    self.logButton = logButton;
    self.connectionsButton = connectionsButton;
    [self setupLogButton];
    [self setupConnectionButton];
}

- (void)setupButtonsTabBarWithLog:(UIButton*)logButton connections:(UIButton*)connectionsButton filter:(UIButton*)filterButton andActiveFilterImage:(UIImageView*)activeImageView {
    self.logButton = logButton;
    self.connectionsButton = connectionsButton;
    self.filterButton = filterButton;
    self.activeFilterImageView = activeImageView;
    [self setupLogButton];
    [self setupConnectionButton];
    [self setupFilterButton];
}

- (void)setReferenceForPresentationView:(UIView*)presentationView andDiscoveredDevicesView:(UIView*)discoveredDevicesView {
    self.presentationView = presentationView;
    self.discoveredDevicesView = discoveredDevicesView;
}

- (void)setReferenceForExpandableControllerView:(UIView*)expandableControllerView andExpandableControllerHeight:(NSLayoutConstraint*)expandableControllerHeight {
    self.expandableControllerView = expandableControllerView;
    self.expandableControllerHeight = expandableControllerHeight;
}

- (void)setValueForCornerRadius:(CGFloat)cornerRadius {
    self.cornerRadius = cornerRadius;
}

- (SILBrowserLogViewController*)logButtonWasTappedAction {
    SILBrowserLogViewController* logVC;
    
    if (self.logButton.isSelected == NO) {
        BOOL anyButtonSelected = [self isAnyButtonSelected];
        [self prepareSceneDependOnButtonSelection:anyButtonSelected];
        
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:SILAppBluetoothBrowserHome bundle:nil];
        logVC = [storyboard instantiateViewControllerWithIdentifier:SILSceneLog];
    
        [self insertIntoContainerExpandableController:logVC];
        [self animateExpandableViewControllerIfNeeded:anyButtonSelected];
        self.expandingViewController = logVC;
        
        [self.logButton setSelected:YES];
    } else {
        [self prepareSceneForRemoveExpandingController];
    }
    
    return logVC;
}

- (SILBrowserConnectionsViewController*)connectionsButtonWasTappedAction {
    SILBrowserConnectionsViewController* connectionVC;
    
    if (self.connectionsButton.isSelected == NO) {
        BOOL anyButtonSelected = [self isAnyButtonSelected];
        [self prepareSceneDependOnButtonSelection:anyButtonSelected];
    
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:SILAppBluetoothBrowserHome bundle:nil];
        connectionVC = [storyboard instantiateViewControllerWithIdentifier:SILSceneConnections];
    
        [self insertIntoContainerExpandableController:connectionVC];
        [self animateExpandableViewControllerIfNeeded:anyButtonSelected];
        self.expandingViewController = connectionVC;
        
        [self.connectionsButton setSelected:YES];
    } else {
        [self prepareSceneForRemoveExpandingController];
    }
    
    return connectionVC;
}

- (SILBrowserFilterViewController*)filterButtonWasTappedAction {
    SILBrowserFilterViewController* filterVC;
    
    if (self.filterButton.isSelected == NO) {
        BOOL anyButtonSelected = [self isAnyButtonSelected];
        [self prepareSceneDependOnButtonSelection:anyButtonSelected];
        
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:SILAppBluetoothBrowserHome bundle:nil];
        filterVC = [storyboard instantiateViewControllerWithIdentifier:SILSceneFilter];
    
        [self insertIntoContainerExpandableController:filterVC];
        [self animateExpandableViewControllerIfNeeded:anyButtonSelected];
        self.expandingViewController = filterVC;
        
        [self.filterButton setSelected:YES];
    } else {
        [self prepareSceneForRemoveExpandingController];
    }
    
    return filterVC;
}

- (void)removeExpandingControllerIfNeeded {
    [self prepareSceneForRemoveExpandingController];
}

- (void)updateConnectionsButtonTitle:(NSUInteger)connections {
    NSString* const AppendingConnections = @" Connections";
    NSString* connectionsText = [NSString stringWithFormat:@"%lu%@", (unsigned long)connections, AppendingConnections];
    [self.connectionsButton setTitle:connectionsText forState:UIControlStateNormal];
    [self.connectionsButton setTitle:connectionsText forState:UIControlStateSelected];
}

#pragma mark - Private Functions

- (void)setupLogButton {
    UIEdgeInsets const ImageInsetsForLogButton = {0, 16, 0 ,8};
    UIEdgeInsets const TitleEdgeInsetsForLogButton = {0, 20., 0, 0};
    
    [self.logButton setTintColor:[UIColor clearColor]];
    [self.logButton setImage:[[UIImage imageNamed:SILImageLogOff] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState: UIControlStateNormal];
    [self.logButton setImage:[[UIImage imageNamed:SILImageLogOn] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateSelected];
    self.logButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.logButton.imageEdgeInsets = ImageInsetsForLogButton;
    [self.logButton setTitleEdgeInsets:TitleEdgeInsetsForLogButton];
    self.logButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.logButton.titleLabel.font = [UIFont robotoMediumWithSize:[UIFont getMiddleFontSize]];
    [self.logButton setTitleColor:[UIColor sil_primaryTextColor] forState:UIControlStateNormal];
    [self.logButton setTitleColor:[UIColor sil_regularBlueColor] forState:UIControlStateSelected];
}

- (void)setupConnectionButton {
    UIEdgeInsets const ImageInsetsForConnectionsButton = {0, 8, 0 ,8};
    UIEdgeInsets const TitleEdgeInsetsForConnectionsButton = {0, 8, 0, 0};
    
    [self.connectionsButton setTintColor:[UIColor clearColor]];
    [self.connectionsButton setImage:[[UIImage imageNamed:SILImageConnectOff] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [self.connectionsButton setImage:[[UIImage imageNamed:SILImageConnectOn] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateSelected];
    self.connectionsButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.connectionsButton.imageEdgeInsets = ImageInsetsForConnectionsButton;
    [self.connectionsButton setTitleEdgeInsets:TitleEdgeInsetsForConnectionsButton];
    self.connectionsButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.connectionsButton.titleLabel.font = [UIFont robotoMediumWithSize:[UIFont getMiddleFontSize]];
    [self.connectionsButton setTitleColor:[UIColor sil_primaryTextColor] forState:UIControlStateNormal];
    [self.connectionsButton setTitleColor:[UIColor sil_regularBlueColor] forState:UIControlStateSelected];
}

- (void)setupFilterButton {
    UIEdgeInsets const ImageInsetsForFilterButton = {0, 8, 0 ,12};
    UIEdgeInsets const TitleEdgeInsetsForFilterButton = {0, 8, 0, 8};
    
    [self.filterButton setTintColor:[UIColor clearColor]];
    [self.filterButton setImage:[[UIImage imageNamed:SILImageSearchOff] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [self.filterButton setImage:[[UIImage imageNamed:SILImageSearchOn] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateSelected];
    self.filterButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.filterButton.imageEdgeInsets = ImageInsetsForFilterButton;
    [self.filterButton setTitleEdgeInsets:TitleEdgeInsetsForFilterButton];
    self.filterButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.filterButton.titleLabel.font = [UIFont robotoMediumWithSize:[UIFont getMiddleFontSize]];
    [self.filterButton setTitleColor:[UIColor sil_primaryTextColor] forState:UIControlStateNormal];
    [self.filterButton setTitleColor:[UIColor sil_regularBlueColor] forState:UIControlStateSelected];
    [self.activeFilterImageView setHidden:YES];
}

- (BOOL)isAnyButtonSelected {
    return ! (self.logButton.isSelected == NO && self.connectionsButton.isSelected == NO && self.filterButton.isSelected == NO);
}

- (void)deselectAllButtons {
    [self.logButton setSelected:NO];
    [self.connectionsButton setSelected:NO];
    [self.filterButton setSelected:NO];
}

- (void)prepareSceneDependOnButtonSelection:(BOOL)anyButtonSelected {
    if (anyButtonSelected) {
        [self prepareSceneForChangeExpandableView];
    } else {
        [self prepareSceneForExpandableView];
    }
    
    [self customizeExpandableViewAppearance];
}

- (void)prepareSceneForChangeExpandableView {
    [self deselectAllButtons];
    [self removeExpandableViewController];
}

- (void)prepareSceneForExpandableView {
    if (self.expandingViewController != nil) {
        [self prepareSceneForRemoveExpandingController];
    }
    
    [self attachBlurEffectView];
}

- (void)customizeExpandableViewAppearance {
    self.cornerRadius = 20.0;
    self.expandableControllerHeight.constant = self.presentationView.frame.size.height * 0.9;
}

- (void)customizeSceneWithoutExpandableViewContoller {
    self.cornerRadius = 0.0;
    self.expandableControllerHeight.constant = CollapsedViewHeight;
}

- (void)removeExpandableViewController {
    [self.browserViewController willMoveToParentViewController:nil];
    [self.expandingViewController.view removeFromSuperview];
    [self.expandingViewController removeFromParentViewController];
    self.expandingViewController = nil;
}

- (void)insertIntoContainerExpandableController:(UIViewController*)viewController {
    [self.browserViewController addChildViewController:viewController];
    [self.expandableControllerView addSubview:viewController.view];
    viewController.view.frame = self.expandableControllerView.frame;
    viewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [viewController didMoveToParentViewController:self.browserViewController];
    
    [self.browserViewController.view setNeedsUpdateConstraints];
}

- (void)animateExpandableViewControllerIfNeeded:(BOOL)anyButtonSelected {
    if (!anyButtonSelected) {
        [self animateExpandableViewController];
    }
}

- (void)animateExpandableViewController {
    [UIView animateWithDuration:AnimationExpandableControllerTime delay:AnimationExpandableControllerDelay options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionTransitionCurlDown animations:^{
        [self.browserViewController.view layoutIfNeeded];
    } completion:nil];
}

- (void)prepareSceneForRemoveExpandingController {
    [self deselectAllButtons];
    [self removeExpandableViewController];
    [self customizeSceneWithoutExpandableViewContoller];
    [self animateExpandableViewController];
    [self removeBlurEffectView];
}

- (void)attachBlurEffectView {
    UIBlurEffect* blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.effectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.effectView.frame = self.presentationView.frame;
    [self.discoveredDevicesView addSubview:self.effectView];
}

- (void)removeBlurEffectView {
    [self.effectView removeFromSuperview];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    if (_cornerRadius != cornerRadius) {
        _cornerRadius = cornerRadius;
        [self adjustView];
    }
}

- (void)adjustView {
    if (self.expandableControllerView != nil) {
        self.expandableControllerView.layer.cornerRadius = self.cornerRadius;
        self.expandableControllerView.layer.maskedCorners = kCALayerMaxXMaxYCorner | kCALayerMinXMaxYCorner;
        self.expandableControllerView.clipsToBounds = YES;
    }
}

@end
