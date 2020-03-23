//
//  SILHomeTabBarViewController.m
//  BlueGecko
//
//  Created by Kamil Czajka on 13/12/2019.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

#import "SILHomeTabBarViewController.h"
#import "UIImage+SILImages.h"
#import "SILAppSelectionViewController.h"
#import "SILApp.h"

@interface SILHomeTabBarViewController ()

@end

@implementation SILHomeTabBarViewController

CGFloat const VerticalOffsetForText = -16.0;
CGFloat const HorizontalOffsetForText = 0.0;
NSInteger const SystemVersion = 13.0;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupTabsAppearance];
}

- (void)setupTabsAppearance {
    self.tabBar.barTintColor = [UIColor sil_cardBackgroundColor];
    [self setupDemoTabItem];
    [self setupDevelopTabItem];
    [self setupTabBarItemFont];
    [self setupTabBarTextPosition];
}

- (void)setupDemoTabItem {
    self.tabBar.items[0].selectedImage = [[UIImage imageNamed:SILImageHomeTabBarDemoOn] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.tabBar.items[0].image = [[UIImage imageNamed:SILImageHomeTabBarDemoOff] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (void)setupDevelopTabItem {
    self.tabBar.items[1].selectedImage = [[UIImage imageNamed:SILImageHomeTabBarDevelopOn] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.tabBar.items[1].image = [[UIImage imageNamed:SILImageHomeTabBarDevelopOff] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (void)setupTabBarItemFont {
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
              NSForegroundColorAttributeName: [UIColor sil_backgroundColor],
              NSFontAttributeName: [UIFont robotoRegularWithSize:[UIFont getMiddleFontSize]],
              }
    forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
              NSForegroundColorAttributeName: [UIColor sil_backgroundColor],
              NSFontAttributeName: [UIFont robotoRegularWithSize:[UIFont getMiddleFontSize]],
              }
    forState:UIControlStateSelected];
}

- (void)setupTabBarTextPosition {
    if ([self isIPadOS12] == false) {
        [UITabBarItem appearance].titlePositionAdjustment = UIOffsetMake(HorizontalOffsetForText, VerticalOffsetForText);
    }
}

- (BOOL)isIPadOS12 {
    return ([[[UIDevice currentDevice] systemVersion] floatValue] < SystemVersion && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

@end
