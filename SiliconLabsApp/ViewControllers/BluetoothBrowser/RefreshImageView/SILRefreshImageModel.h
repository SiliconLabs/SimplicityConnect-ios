//
//  SILRefreshImageModel.h
//  BlueGecko
//
//  Created by Grzegorz Janosz on 23/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SILRefreshImageModel : NSObject

@property NSLayoutConstraint *topRefreshImageConstraint;
@property UIView *emptyView;
@property UITableView *tableView;
@property (nonatomic, copy) void (^reloadAction)(void);

-(instancetype)initWithConstraint:(NSLayoutConstraint *)constraint
                    withEmptyView:(UIView *)emptyView
                    withTableView:(UITableView *)tableView
                    andWithReloadAction:(void (^)(void))reloadAction;

@end

NS_ASSUME_NONNULL_END
