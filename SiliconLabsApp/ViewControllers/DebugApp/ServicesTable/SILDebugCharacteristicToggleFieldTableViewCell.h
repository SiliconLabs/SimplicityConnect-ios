//
//  SILDebugCharacteristicToggleFieldTableViewCell.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/28/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILCharacteristicEditEnabler.h"
@class SILBitRowModel;

@interface SILDebugCharacteristicToggleFieldTableViewCell : UITableViewCell
@property (strong, nonatomic) id<SILCharacteristicEditEnablerDelegate> editDelegate;
- (void)configureWithBitRowModel:(SILBitRowModel *)bitRowModel;
@end
