//
//  SILBeaconRegistryEntryCell.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/18/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILBeaconRegistryEntryViewModel.h"

@interface SILBeaconRegistryEntryCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *beaconSeparatorView;
@property (weak, nonatomic) IBOutlet UIImageView *beaconIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *beaconName;
@property (weak, nonatomic) IBOutlet UILabel *beaconRSSIValue;
@property (weak, nonatomic) IBOutlet UILabel *beaconType;
@property (weak, nonatomic) IBOutlet UILabel *beaconDistanceValue;
@property (weak, nonatomic) IBOutlet UIImageView *beaconDistanceImageView;

- (void)configureWithViewModel:(SILBeaconRegistryEntryViewModel *)viewModel;
@end
