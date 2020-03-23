//
//  SILBrowserConnectionsTableViewCell.h
//  BlueGecko
//
//  Created by Kamil Czajka on 29/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SILBrowserConnectionsTableViewCell : UITableViewCell

- (void)setDeviceName:(NSString*)deviceName index:(NSInteger)index andIsSelected:(BOOL)isSelected;

@end

NS_ASSUME_NONNULL_END
