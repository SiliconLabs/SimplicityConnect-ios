//
//  SILAppDelegate.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/12/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILAppDelegate.h"
#import "SILAppearance.h"
#import "SILAppSelectionViewController.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@interface SILAppDelegate ()

@end

@implementation SILAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [SILAppearance setupAppearance];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    SILAppSelectionViewController *vc = [[SILAppSelectionViewController alloc] init];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    self.window.rootViewController = nc;

    [self.window makeKeyAndVisible];
    
    [Fabric with:@[CrashlyticsKit]];

    return YES;
}

@end
