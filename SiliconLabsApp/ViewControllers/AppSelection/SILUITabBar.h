//
//  SILUITabBar.h
//  BlueGecko
//
//  Created by Kamil Czajka on 16/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

IB_DESIGNABLE
@interface SILUITabBar : UITabBar

- (void)setMuliplierForSelectedIndex:(NSUInteger)index;

@property (nonatomic, assign) IBInspectable CGFloat height;

@end

NS_ASSUME_NONNULL_END
