//
//  SILDebugCharacteristicToggleFieldTableViewCell.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/28/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SILBitRowModel;

@interface SILDebugCharacteristicToggleFieldTableViewCell : UITableViewCell
- (void)configureWithBitRowModel:(SILBitRowModel *)bitRowModel;
@end
