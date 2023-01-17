//
//  SILExitPopupViewController.m
//  SiliconLabsApp
//
//  Created by Grzegorz Janosz on 17/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILExitPopupViewController.h"

@interface SILExitPopupViewController ()

@property (weak, nonatomic) IBOutlet UIButton *okButton;
@property (weak, nonatomic) IBOutlet SILSwitch *confirmSwitch;

@end

@implementation SILExitPopupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _okButton.layer.cornerRadius = CornerRadiusForButtons;
    [self.confirmSwitch setIsOn: NO];
}

#pragma mark - UIViewController Methods

- (CGSize)preferredContentSize {
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return CGSizeMake(500, 270);
    } else {
        return CGSizeMake(350, 220);
    }
}

- (IBAction)okWasTapped:(id)sender {
    [self.delegate okWasTappedInExitPopupWithSwitchState:[_confirmSwitch isOn]];
}

- (IBAction)cancelWasTapped:(id)sender {
    [self.delegate cancelWasTappedInExitPopup];
}



@end
