//
//  SILBrowserLogTableViewCell.h
//  BlueGecko
//
//  Created by Kamil Czajka on 29/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILLogDataModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SILBrowserLogTableViewCell : UITableViewCell

- (void)setValues:(SILLogDataModel*)log;

@end

NS_ASSUME_NONNULL_END
