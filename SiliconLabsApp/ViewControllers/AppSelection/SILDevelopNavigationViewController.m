//
//  SILDevelopNavigationViewController.m
//  BlueGecko
//
//  Created by Kamil Czajka on 24/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILDevelopNavigationViewController.h"

@interface SILDevelopNavigationViewController () <UINavigationControllerDelegate>

@end

@implementation SILDevelopNavigationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
    // Do any additional setup after loading the view.
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([viewController isKindOfClass:[SILAppSelectionViewController class]]) {
        SILAppSelectionViewController* developController = viewController;
        developController.appsArray = [SILApp developApps];
        developController.isDisconnectedIntentionally = NO;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
