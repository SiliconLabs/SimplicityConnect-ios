//
//  SILDeviceSelectionCollectionViewCell.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/23/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILDeviceSelectionCollectionViewCell.h"
#import "UIImage+SILImages.h"

NSString * const SILDeviceSelectionCollectionViewCellIdentifier = @"SILDeviceSelectionCollectionViewCellIdentifier";

CGFloat const SILDeviceSelectionViewControllerReloadThreshold = 1.0;

@interface SILDeviceSelectionCollectionViewCell ()

@end

@implementation SILDeviceSelectionCollectionViewCell

- (void)configureCellForPeripheral:(SILDiscoveredPeripheral*)discoveredPeripheral andApplication:(SILApp*)app {
    [self setDeviceNameForPeripheral:discoveredPeripheral];
    if (app.appType == SILAppTypeConnectedLighting) {
        [self showDbmImageForPeripheral:discoveredPeripheral];
    } else {
        [self hideDbmTypeImageView];
    }
    [self setRSSIImageForPeripheral:discoveredPeripheral];
}

- (void)configureCellForThunderboardDevice:(DiscoveredDeviceDisplay *)device {

    self.deviceNameLabel.text = device.name;
    [self.dmpTypeImageView setHidden:YES];
    self.dmpTypeImageView.image = nil;
    
    NSNumber *rssi = device.RSSI != nil ? device.RSSI : 0;
    _deviceRSSILabel.text = [NSString stringWithFormat:@"%@ dBm", rssi];
    if ([rssi integerValue] > SILConstantsStrongSignalThreshold) {
        self.signalImageView.image = [UIImage imageNamed: SILImageNameBTStrong];
    } else if ([rssi integerValue] > SILConstantsMediumSignalThreshold) {
        self.signalImageView.image = [UIImage imageNamed: SILImageNameBTMedium];
    } else {
        self.signalImageView.image = [UIImage imageNamed: SILImageNameBTWeak];
    }
}

- (void)setDeviceNameForPeripheral:(SILDiscoveredPeripheral*)discoveredPeripheral {
    self.deviceNameLabel.text = discoveredPeripheral.advertisedLocalName;
    
    if ([self.deviceNameLabel.text length] == 0) {
        self.deviceNameLabel.text = @"<unknown>";
    }
}

- (void)showDbmImageForPeripheral:(SILDiscoveredPeripheral*)discoveredPeripheral {
    NSString *dmpImage;
        
    if (discoveredPeripheral.isDMPConnectedLightConnect) {
        dmpImage = @"iconBleConnect";
    } else if (discoveredPeripheral.isDMPConnectedLightThread) {
        dmpImage = @"iconThread";
    } else if (discoveredPeripheral.isDMPConnectedLightZigbee) {
        dmpImage = @"iconZigbee";
    } else {
        dmpImage = @"iconProprietary";
    }
        
    self.dmpTypeImageView.hidden = NO;
    self.dmpTypeImageView.image = [UIImage imageNamed:dmpImage];
}

- (void)hideDbmTypeImageView {
    self.dmpTypeImageView.hidden = YES;
    self.dmpTypeImageView.image = nil;
}

- (void)setRSSIImageForPeripheral:(SILDiscoveredPeripheral*)discoveredPeripheral {
    NSInteger smoothedRSSIValue = [[discoveredPeripheral.rssiMeasurementTable averageRSSIMeasurementInPastTimeInterval:SILDeviceSelectionViewControllerReloadThreshold] integerValue];
    _deviceRSSILabel.text = [NSString stringWithFormat:@"%ld dBm", (long)smoothedRSSIValue];
    if (smoothedRSSIValue > SILConstantsStrongSignalThreshold) {
        self.signalImageView.image = [UIImage imageNamed:SILImageNameBTStrong];
    } else if (smoothedRSSIValue > SILConstantsMediumSignalThreshold) {
        self.signalImageView.image = [UIImage imageNamed:SILImageNameBTMedium];
    } else {
        self.signalImageView.image = [UIImage imageNamed:SILImageNameBTWeak];
    }
}

@end
