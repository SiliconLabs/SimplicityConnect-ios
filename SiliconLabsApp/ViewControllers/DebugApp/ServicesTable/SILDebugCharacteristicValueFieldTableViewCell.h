//
//  SILDebugCharacteristicValueFieldTableViewCell.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/28/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILCharacteristicEditEnabler.h"

@class SILValueFieldRowModel;

@interface SILDebugCharacteristicValueFieldTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (strong, nonatomic) id<SILCharacteristicEditEnablerDelegate> editDelegate;
- (void)configureWithValueModel:(SILValueFieldRowModel *)valueModel;
@end
