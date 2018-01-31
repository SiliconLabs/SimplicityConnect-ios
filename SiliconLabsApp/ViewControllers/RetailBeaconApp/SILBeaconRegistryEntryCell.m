//
//  SILBeaconRegistryEntryCell.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/18/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILBeaconRegistryEntryCell.h"

@implementation SILBeaconRegistryEntryCell

- (void)configureWithViewModel:(SILBeaconRegistryEntryViewModel *)viewModel {
    _beaconName.text = viewModel.name;
    _beaconType.text = viewModel.type;
    _beaconIconImageView.image = viewModel.image;
    UIImage* distanceImage = viewModel.distanceImage;
    if (distanceImage != nil) {
        _beaconDistanceImageView.image = distanceImage;
    }
    _beaconDistanceValue.text = viewModel.distanceName;
    _beaconRSSIValue.text = viewModel.formattedRSSI;
}

@end
