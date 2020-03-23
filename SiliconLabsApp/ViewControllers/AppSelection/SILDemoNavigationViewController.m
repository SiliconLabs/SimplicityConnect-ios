//
//  SILDemoNavigationViewController.m
//  BlueGecko
//
//  Created by Kamil Czajka on 24/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILDemoNavigationViewController.h"
#import "SILAppSelectionViewController.h"

@interface SILDemoNavigationViewController () <UINavigationControllerDelegate>

@end

@implementation SILDemoNavigationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([viewController isKindOfClass:[SILAppSelectionViewController class]]) {
        SILAppSelectionViewController* demoController = viewController;
        demoController.appsArray = [SILApp demoApps];
    }
}

@end
