
#import "UITableView+Utils.h"
#import "UIView+IPAncestry.h"

@implementation UITableView (Utils)

- (void)ip_setZeroSeparatorInsets {
    if ([self respondsToSelector:@selector(setSeparatorInset:)]) {
        [self setSeparatorInset:UIEdgeInsetsZero];
    }

    if ([self respondsToSelector:@selector(setLayoutMargins:)]) {
        [self setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)ip_adjustInsetsForBottomLayoutGuideHeight:(UIViewController *)controller {
    self.contentInset = UIEdgeInsetsMake(0, 0, controller.bottomLayoutGuide.length, 0);
    self.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, controller.bottomLayoutGuide.length, 0);
}

@end

@implementation UITableViewCell (Utils)

- (void)ip_setZeroSeparatorInsets {
    if ([self respondsToSelector:@selector(setSeparatorInset:)]) {
        [self setSeparatorInset:UIEdgeInsetsZero];
    }

    if ([self respondsToSelector:@selector(setLayoutMargins:)]) {
        [self setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (UITableView *)ip_owningTableView {
    __block UITableView *tableView = nil;
    [self enumerateSuperviewsWithBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        if ([view isKindOfClass:[UITableView class]]) {
            *stop = YES;
            tableView = (UITableView *)view;
        }
    }];
    return tableView;
}

@end

