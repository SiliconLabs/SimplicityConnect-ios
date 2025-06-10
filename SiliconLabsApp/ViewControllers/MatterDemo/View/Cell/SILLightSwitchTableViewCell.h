//
//  SILLightSwitchTableViewCell.h
//  BlueGecko
//
//  Created by Mantosh Kumar on 19/02/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILSelectedMatterDeviceCell.h"
#include "CHIPUIViewUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface SILLightSwitchTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *deviceBGView;

@property (weak, nonatomic) IBOutlet UIImageView *deviceIconImage;
@property (weak, nonatomic) IBOutlet UIImageView *tickMarkImage;
@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;

- (void)setupCell:(NSDictionary *) deviceInfo;

@end

NS_ASSUME_NONNULL_END
