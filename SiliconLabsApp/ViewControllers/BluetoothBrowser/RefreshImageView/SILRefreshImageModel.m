//
//  SILRefreshImageModel.m
//  BlueGecko
//
//  Created by Grzegorz Janosz on 23/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILRefreshImageModel.h"

@implementation SILRefreshImageModel

-(instancetype)initWithConstraint:(NSLayoutConstraint *)constraint
                    withEmptyView:(UIView *)emptyView
                    withTableView:(UITableView *)tableView
                andWithReloadAction:(void (^)(void))reloadAction {
    self = [super init];
    if (self) {
        self.topRefreshImageConstraint = constraint;
        self.emptyView = emptyView;
        self.tableView = tableView;
        self.reloadAction = reloadAction;
    }
    return self;
}

@end
