#import "UIView+Constraints.h"

NSString *const IPConstraintKeyTop = @"IPConstraintKeyTop";
NSString *const IPConstraintKeyLeft = @"IPConstraintKeyLeft";
NSString *const IPConstraintKeyBottom = @"IPConstraintKeyBottom";
NSString *const IPConstraintKeyRight = @"IPConstraintKeyRight";

@implementation UIView (CBConstraints)

- (ConstraintDictionary *)constrainView:(UIView *)view top:(CGFloat)top left:(CGFloat)left bottom:(CGFloat)bottom right:(CGFloat)right {
    return [self constrainView:view toInsets:UIEdgeInsetsMake(top, left, bottom, right)];
}

- (ConstraintDictionary *)constrainView:(UIView *)view toInsets:(UIEdgeInsets)insets {
    NSMutableDictionary *constraints = [NSMutableDictionary dictionary];
    if (insets.top != NSNotFound) {
        NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:view
                                                               attribute:NSLayoutAttributeTop
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self
                                                               attribute:NSLayoutAttributeTop
                                                              multiplier:1.0
                                                                constant:insets.top];
        constraints[IPConstraintKeyTop] = top;
    }
    if (insets.left != NSNotFound) {
        NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:view
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1.0
                                                                 constant:insets.left];
        constraints[IPConstraintKeyLeft] = left;
    }
    if (insets.bottom != NSNotFound) {
        NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:view
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1.0
                                                                   constant:-insets.bottom];
        constraints[IPConstraintKeyBottom] = bottom;
    }
    if (insets.right != NSNotFound) {
        NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:view
                                                                 attribute:NSLayoutAttributeRight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self
                                                                 attribute:NSLayoutAttributeRight
                                                                multiplier:1.0
                                                                  constant:-insets.right];
        constraints[IPConstraintKeyRight] = right;
    }

    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraints:constraints.allValues];
    return constraints;
}

- (NSLayoutConstraint *)constrainViewToEqualWidth:(UIView *)view {
    return [self constrainViewToEqualWidth:view constant:0.0 multiplier:1.0];
}

- (NSLayoutConstraint *)constrainViewToEqualWidth:(UIView *)view constant:(CGFloat)constant multiplier:(CGFloat)multiplier {
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:view
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeWidth
                                                            multiplier:multiplier
                                                              constant:constant];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraint:width];
    return width;
}

- (NSLayoutConstraint *)constrainViewToEqualHeight:(UIView *)view {
    return [self constrainViewToEqualHeight:view constant:0.0 multiplier:1.0];
}

- (NSLayoutConstraint *)constrainViewToEqualHeight:(UIView *)view constant:(CGFloat)constant multiplier:(CGFloat)multiplier {
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:view
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self
                                                              attribute:NSLayoutAttributeHeight
                                                             multiplier:multiplier
                                                               constant:constant];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraint:height];
    return height;
}

- (NSLayoutConstraint *)constrainView:(UIView *)view toWidth:(CGFloat)width {
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:view
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1.0
                                                                        constant:width];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraint:widthConstraint];
    return widthConstraint;
}

- (NSLayoutConstraint *)constrainView:(UIView *)view toHeight:(CGFloat)height {
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:view
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0
                                                                         constant:height];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraint:heightConstraint];
    return heightConstraint;
}

- (NSLayoutConstraint *)constrainView:(UIView *)view toAspectRatio:(CGFloat)aspectRatio {
    return [self constrainView:view attribute:NSLayoutAttributeWidth toView:view attribute:NSLayoutAttributeHeight constant:0.0 multiplier:aspectRatio];
}

- (NSLayoutConstraint *)constrainView:(UIView *)view aboveView:(UIView *)positioningView {
    return [self constrainView:view attribute:NSLayoutAttributeBottom toView:positioningView attribute:NSLayoutAttributeTop];
}

- (NSLayoutConstraint *)constrainView:(UIView *)view aboveView:(UIView *)positioningView withOffset:(CGFloat)offset {
    return [self constrainView:view attribute:NSLayoutAttributeBottom toView:positioningView attribute:NSLayoutAttributeTop constant:offset multiplier:1.0];
}

- (NSLayoutConstraint *)constrainView:(UIView *)view belowView:(UIView *)positioningView {
    return [self constrainView:view attribute:NSLayoutAttributeTop toView:positioningView attribute:NSLayoutAttributeBottom];
}

- (NSLayoutConstraint *)constrainView:(UIView *)view belowView:(UIView *)positioningView withOffset:(CGFloat)offset {
    return [self constrainView:view attribute:NSLayoutAttributeTop toView:positioningView attribute:NSLayoutAttributeBottom constant:offset multiplier:1.0];
}

- (NSLayoutConstraint *)constrainView:(UIView *)view leftOfView:(UIView *)positioningView {
    return [self constrainView:view attribute:NSLayoutAttributeRight toView:positioningView attribute:NSLayoutAttributeLeft];
}

- (NSLayoutConstraint *)constrainView:(UIView *)view leftOfView:(UIView *)positioningView withOffset:(CGFloat)offset {
    return [self constrainView:view attribute:NSLayoutAttributeRight toView:positioningView attribute:NSLayoutAttributeLeft constant:offset multiplier:1.0];
}

- (NSLayoutConstraint *)constrainView:(UIView *)view rightOfView:(UIView *)positioningView {
    return [self constrainView:view attribute:NSLayoutAttributeLeft toView:positioningView attribute:NSLayoutAttributeRight];
}

- (NSLayoutConstraint *)constrainView:(UIView *)view rightOfView:(UIView *)positioningView withOffset:(CGFloat)offset {
    return [self constrainView:view attribute:NSLayoutAttributeLeft toView:positioningView attribute:NSLayoutAttributeRight constant:offset multiplier:1.0];
}

- (NSLayoutConstraint *)constrainView:(UIView *)view toTopOfView:(UIView *)positioningView {
    return [self constrainView:view attribute:NSLayoutAttributeTop toView:positioningView attribute:NSLayoutAttributeTop];
}

- (NSLayoutConstraint *)constrainView:(UIView *)view toBottomOfView:(UIView *)positioningView {
    return [self constrainView:view attribute:NSLayoutAttributeBottom toView:positioningView attribute:NSLayoutAttributeBottom];
}

- (NSLayoutConstraint *)constrainView:(UIView *)view toWidthOfView:(UIView *)sizingView {
    return [self constrainView:view attribute:NSLayoutAttributeWidth toView:sizingView attribute:NSLayoutAttributeWidth];
}

- (NSLayoutConstraint *)constrainView:(UIView *)view toHeightOfView:(UIView *)sizingView {
    return [self constrainView:view attribute:NSLayoutAttributeHeight toView:sizingView attribute:NSLayoutAttributeHeight];
}

- (NSLayoutConstraint *)constrainView:(UIView *)viewA attribute:(NSLayoutAttribute)attributeA toView:(UIView *)viewB attribute:(NSLayoutAttribute)attributeB {
    return [self constrainView:viewA
                     attribute:attributeA
                        toView:viewB
                     attribute:attributeB
                      constant:0.0
                    multiplier:1.0];
}

- (NSLayoutConstraint *)constrainView:(UIView *)viewA attribute:(NSLayoutAttribute)attributeA toView:(UIView *)viewB attribute:(NSLayoutAttribute)attributeB constant:(CGFloat)constant multiplier:(CGFloat)multiplier {
    return [self constrainView:viewA
                     attribute:attributeA
                        toView:viewB
                     attribute:attributeB
                      constant:constant
                    multiplier:multiplier
                      relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)constrainView:(UIView *)viewA attribute:(NSLayoutAttribute)attributeA toView:(UIView *)viewB attribute:(NSLayoutAttribute)attributeB constant:(CGFloat)constant multiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation {
    NSLayoutConstraint *bind = [NSLayoutConstraint constraintWithItem:viewA
                                                            attribute:attributeA
                                                            relatedBy:relation
                                                               toItem:viewB
                                                            attribute:attributeB
                                                           multiplier:multiplier
                                                             constant:constant];

    viewA.translatesAutoresizingMaskIntoConstraints = NO;
    viewB.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraint:bind];
    return bind;
}

- (NSLayoutConstraint *)constrainViewToLeft:(UIView *)view {
    return [self constrainViewToLeft:view withInset:0];
}

- (NSLayoutConstraint *)constrainViewToLeft:(UIView *)view withInset:(CGFloat)inset {
    return [self constrainView:view toInsets:UIEdgeInsetsMake(NSNotFound, inset, NSNotFound, NSNotFound)][IPConstraintKeyLeft];
}

- (NSLayoutConstraint *)constrainViewToRight:(UIView *)view {
    return [self constrainViewToRight:view withInset:0];
}

- (NSLayoutConstraint *)constrainViewToRight:(UIView *)view withInset:(CGFloat)inset {
    return [self constrainView:view toInsets:UIEdgeInsetsMake(NSNotFound, NSNotFound, NSNotFound, -inset)][IPConstraintKeyRight];
}

- (NSLayoutConstraint *)constrainViewToTop:(UIView *)view {
    return [self constrainViewToTop:view withInset:0];
}

- (NSLayoutConstraint *)constrainViewToTop:(UIView *)view withInset:(CGFloat)inset {
    return [self constrainView:view toInsets:UIEdgeInsetsMake(inset, NSNotFound, NSNotFound, NSNotFound)][IPConstraintKeyTop];
}

- (NSLayoutConstraint *)constrainViewToBottom:(UIView *)view {
    return [self constrainViewToBottom:view withInset:0];
}

- (NSLayoutConstraint *)constrainViewToBottom:(UIView *)view withInset:(CGFloat)inset {
    return [self constrainView:view toInsets:UIEdgeInsetsMake(NSNotFound, NSNotFound, -inset, NSNotFound)][IPConstraintKeyBottom];
}

- (NSLayoutConstraint *)constrainViewToMiddleVertically:(UIView *)view {
    return [self constrainView:view attribute:NSLayoutAttributeCenterY toView:self attribute:NSLayoutAttributeCenterY];
}

- (NSLayoutConstraint *)constrainViewToMiddleHorizontally:(UIView *)view {
    return [self constrainView:view attribute:NSLayoutAttributeCenterX toView:self attribute:NSLayoutAttributeCenterX];
}

- (NSLayoutConstraint *)constrainTopOfView:(UIView *)view toCenterYWithOffset:(CGFloat)offset {
    return [self constrainView:view
                     attribute:NSLayoutAttributeTop
                        toView:self
                     attribute:NSLayoutAttributeCenterY
                      constant:offset
                    multiplier:1];
}

- (NSLayoutConstraint *)constrainBottomOfView:(UIView *)view toCenterYWithOffset:(CGFloat)offset {
    return [self constrainView:view
                     attribute:NSLayoutAttributeBottom
                        toView:self
                     attribute:NSLayoutAttributeCenterY
                      constant:offset
                    multiplier:1];
}

- (ConstraintDictionary *)constrainViewToAllEdges:(UIView *)view {
    return [self constrainView:view toInsets:UIEdgeInsetsZero];
}

- (ConstraintDictionary *)constrainViewToHorizontalEdges:(UIView *)view {
    return [self constrainView:view toInsets:UIEdgeInsetsMake(NSNotFound, 0, NSNotFound, 0)];
}

@end
