//
//  SILBrowserSettings.m
//  BlueGecko
//
//  Created by Grzegorz Janosz on 18/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILBrowserSettings.h"

NSString * const SILBrowserSettingsDisplayExitWarningPopup = @"SILBrowserSettingsDisplayExitWarningPopup";

@implementation SILBrowserSettings

static BOOL _displayExitWarningPopup;

+ (void)initialize {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
                                                                SILBrowserSettingsDisplayExitWarningPopup: @NO,
                                                              }];

    _displayExitWarningPopup = [[NSUserDefaults standardUserDefaults] boolForKey:SILBrowserSettingsDisplayExitWarningPopup];
}

+ (BOOL)displayExitWarningPopup {
    return _displayExitWarningPopup;
}

+ (void)setDisplayExitWarningPopup:(BOOL)displayExitWarningPopup {
    _displayExitWarningPopup = displayExitWarningPopup;
    [[NSUserDefaults standardUserDefaults] setBool:displayExitWarningPopup forKey:SILBrowserSettingsDisplayExitWarningPopup];
}

@end
