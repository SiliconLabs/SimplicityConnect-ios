//
//  SILServicesServiceTableViewCell.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/6/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILGenericAttributeTableCell.h"

@class SILServiceTableModel;
#if ENABLE_HOMEKIT
@class SILHomeKitServiceTableModel;
#endif

@interface SILDebugServiceTableViewCell : UITableViewCell <SILGenericAttributeTableCell>
- (void)configureWithServiceModel:(SILServiceTableModel *)serviceTableModel;
#if ENABLE_HOMEKIT
- (void)configureWithHomeKitServiceModel:(SILHomeKitServiceTableModel *)homeKitServiceTableModel;
#endif
@end
