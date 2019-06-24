#import "UIView+IPAncestry.h"

@implementation UIView (IPAncestry)

- (void)enumerateSuperviewsWithBlock:(void (^)(UIView *view, NSUInteger idx, BOOL *stop))block {
    UIView *thisView = self;
    NSUInteger index = 0;
    __block BOOL stop = NO;
    while (thisView.superview != nil && stop == NO) {
        block(thisView.superview, index, &stop);
        index++;
        thisView = thisView.superview;
    }
}

- (UIView *)descendantViewPassingTest:(BOOL (^)(UIView *viewToCheck))test {
    if (test(self)) {
        return self;
    }
    for (UIView *subview in self.subviews) {
        UIView *subviewResult = [subview descendantViewPassingTest:test];
        if (subviewResult) {
            return subviewResult;
        }
    }
    return nil;
}

- (NSSet *)allDescendantViewsPassingTest:(BOOL (^)(UIView *viewToCheck))test {
    NSMutableSet *descendantViews = [NSMutableSet set];
    if (test(self)) {
        [descendantViews addObject:self];
    }

    for (UIView *subview in self.subviews) {
        [descendantViews unionSet:[subview allDescendantViewsPassingTest:test]];
    }

    return [descendantViews copy];
}

@end
