//
//  SILCalibrationViewController.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/12/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILCalibrationViewController.h"
#import "SILSettings.h"

@interface SILCalibrationViewController ()

@property (weak, nonatomic) IBOutlet UITextField *beaconNearTextField;
@property (weak, nonatomic) IBOutlet UITextField *beaconFarTextField;

@property (weak, nonatomic) IBOutlet UITextField *fobDeltaThresholdTextField;
@property (weak, nonatomic) IBOutlet UITextField *fobMinDeltaTextField;
@property (weak, nonatomic) IBOutlet UITextField *fobMaxDeltaTextField;

@property (weak, nonatomic) IBOutlet UISwitch *debugSwitch;

@end

@implementation SILCalibrationViewController

- (CGSize)preferredContentSize {
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return CGSizeMake(540, 600);
    } else {
        return CGSizeMake(296, 496);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.debugSwitch.on = [SILSettings displayDebugValues];

    self.beaconNearTextField.text = [NSString stringWithFormat:@"%.2f", [SILSettings nearProximityThreshold]];
    self.beaconFarTextField.text = [NSString stringWithFormat:@"%.2f", [SILSettings farProximityThreshold]];

    self.fobDeltaThresholdTextField.text = [NSString stringWithFormat:@"%ld", lround([SILSettings fobProximityDeltaThreshold])];
    self.fobMinDeltaTextField.text = [NSString stringWithFormat:@"%ld", lround([SILSettings minExpectedFobDelta])];
    self.fobMaxDeltaTextField.text = [NSString stringWithFormat:@"%ld", lround([SILSettings maxExpectedFobDelta])];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [SILSettings setDisplayDebugValues:self.debugSwitch.isOn];

    [SILSettings setNearProximityThreshold:[self.beaconNearTextField.text doubleValue]];
    [SILSettings setFarProximityThreshold:[self.beaconFarTextField.text doubleValue]];

    [SILSettings setFobProximityDeltaThreshold:[self.fobDeltaThresholdTextField.text integerValue]];
    [SILSettings setMinExpectedFobDelta:[self.fobMinDeltaTextField.text integerValue]];
    [SILSettings setMaxExpectedFobDelta:[self.fobMaxDeltaTextField.text integerValue]];
}

@end
