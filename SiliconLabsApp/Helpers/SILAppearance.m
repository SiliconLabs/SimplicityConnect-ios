//
//  SILAppearance.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/26/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILAppearance.h"
#import "UIColor+SILColors.h"
#import "UIImage+SILHelpers.h"
#import <SVProgressHUD/SVProgressHUD.h>

@implementation SILAppearance

+ (void)setupAppearance {
    [self setupNavigationBarAppearance];
    [self setupBarButtonItemAppearance];
    [self setupTextFieldAppearance];
    [self setupSegmentedControlAppearance];
    
    [self setupSVProgressHUD];
}

+ (void)setupSegmentedControlAppearance {
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[UISegmentedControl.class]] setNumberOfLines:2];
    
    UISegmentedControl.appearance.selectedSegmentTintColor = [UIColor sil_bgWhiteColor];
    UISegmentedControl.appearance.backgroundColor = [UIColor sil_lightBlueColor];
    [UISegmentedControl.appearance setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor blackColor] } forState:UIControlStateNormal];
    [UISegmentedControl.appearance setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor blackColor] } forState:UIControlStateSelected];
}

+ (void)setupNavigationBarAppearance {
    UINavigationBarAppearance *x = [UINavigationBarAppearance new];
    x.backgroundColor = UIColor.sil_regularBlueColor;
    x.titleTextAttributes = @{
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSFontAttributeName: [UIFont robotoRegularWithSize:17.0],
    };
    UINavigationBar.appearance.standardAppearance = x;
    UINavigationBar.appearance.compactAppearance = x;
    UINavigationBar.appearance.scrollEdgeAppearance = x;
    
    UITabBarAppearance *tabBarAppearance = [UITabBarAppearance new];
    [tabBarAppearance configureWithOpaqueBackground];
    UITabBar.appearance.standardAppearance = tabBarAppearance;
    
    if (@available(iOS 15.0, *)) {
        UITabBar.appearance.scrollEdgeAppearance = tabBarAppearance;
    }
    
    [UIButton appearanceWhenContainedInInstancesOfClasses:@[UINavigationBar.class]].tintColor = UIColor.whiteColor;
}

+ (void)setupBarButtonItemAppearance {
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                          NSForegroundColorAttributeName: [UIColor sil_bgWhiteColor],
                                                          NSFontAttributeName: [UIFont robotoRegularWithSize: 17.0],
                                                          }
                                                forState:UIControlStateNormal];
}

+ (void)setupTextFieldAppearance {
    [[UITextField appearance] setTintColor:[UIColor sil_siliconLabsRedColor]];
}

+ (void)setupSVProgressHUD {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
}

@end
