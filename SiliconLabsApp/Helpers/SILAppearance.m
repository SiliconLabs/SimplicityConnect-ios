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
    
    [self setupSVProgressHUD];
}

+ (void)setupNavigationBarAppearance {
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor clearColor]];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage sil_imageWithColor:[UIColor sil_siliconLabsRedColor]] forBarMetrics:UIBarMetricsDefault];


    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName: [UIColor whiteColor],
                                                           NSFontAttributeName: [UIFont helveticaNeueMediumWithSize:17.0],
                                                           }];
}

+ (void)setupBarButtonItemAppearance {
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                          NSForegroundColorAttributeName: [UIColor whiteColor],
                                                          NSFontAttributeName: [UIFont helveticaNeueWithSize:17.0],
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
