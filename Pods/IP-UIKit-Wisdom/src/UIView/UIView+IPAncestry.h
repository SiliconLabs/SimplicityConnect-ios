#import <UIKit/UIKit.h>

@interface UIView (IPAncestry)

/*!
 Enumerates through the receiver's superviews until no superviews are found.
 */
- (void)enumerateSuperviewsWithBlock:(void (^)(UIView *view, NSUInteger idx, BOOL *stop))block;

/*!
 Performs a depth first search and returns the first view, including the receiver, that passes the specified test.
 */
- (UIView *)descendantViewPassingTest:(BOOL (^)(UIView *viewToCheck))test;

/*!
 Returns all the descendant views that pass the given test.
 */
- (NSSet *)allDescendantViewsPassingTest:(BOOL (^)(UIView *viewToCheck))test;

@end
