//
//  SILSavedSearchesTableViewCell.h
//  BlueGecko
//
//  Created by Kamil Czajka on 13/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SILSavedSearchesTableViewCell : UITableViewCell

- (void)setValuesForSavedSearch:(NSString*)savedSearchesText andIndex:(NSUInteger)index;
- (void)customizeAppearanceForSelectedState;
- (void)customizeAppearanceForUnselectedState;

@end

NS_ASSUME_NONNULL_END
