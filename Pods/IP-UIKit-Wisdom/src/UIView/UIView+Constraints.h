@import UIKit;

typedef NSDictionary<NSString *, NSLayoutConstraint *> ConstraintDictionary;

/**
 *  When a method returns a dictionary, retrieve the desired contraint by using the following keys:
 */
extern NSString *const IPConstraintKeyTop;
extern NSString *const IPConstraintKeyLeft;
extern NSString *const IPConstraintKeyBottom;
extern NSString *const IPConstraintKeyRight;

@interface UIView (CBConstraints)

/*!
 *  Constrain a view with specified insets.  Use `NSNotFound` to specify edges that should not be set
 *
 *  @param view   the view to constrain
 *  @param insets the insets to use when positioning the view
 */
- (ConstraintDictionary *)constrainView:(UIView *)view toInsets:(UIEdgeInsets)insets;

/*!
 *  Constrain view's left edge to the left edge of the caller
 *
 *  @param view the view to constrain
 */
- (NSLayoutConstraint *)constrainViewToLeft:(UIView *)view;

/*!
 *  Constrain view's left edge to the left edge of the caller with an inset
 *
 *  @param view  the view to constrain
 *  @param inset the inset of the view
 */
- (NSLayoutConstraint *)constrainViewToLeft:(UIView *)view withInset:(CGFloat)inset;

/*!
 *  Constrain view's right edge to the right edge of the caller
 *
 *  @param view the view to constrain
 */
- (NSLayoutConstraint *)constrainViewToRight:(UIView *)view;

/*!
 *  Constrain view's right edge to the right edge of the caller with an inset
 *
 *  @param view  the view to constrain
 *  @param inset the inset to use when positioning the view
 */
- (NSLayoutConstraint *)constrainViewToRight:(UIView *)view withInset:(CGFloat)inset;

/*!
 *  Constrain view's top edge to the top edge of the caller
 *
 *  @param view the view to constrain
 */
- (NSLayoutConstraint *)constrainViewToTop:(UIView *)view;

/*!
 *  Constrain view's top edge to the top edge of the caller with specified inset
 *
 *  @param view  the view to constrain
 *  @param inset the inset to use when positioning the view
 */
- (NSLayoutConstraint *)constrainViewToTop:(UIView *)view withInset:(CGFloat)inset;

/*!
 *  Constrain view's bottom edge to the bottom edge of the caller
 *
 *  @param view the view to constrain
 */
- (NSLayoutConstraint *)constrainViewToBottom:(UIView *)view;

/*!
 *  Constrain view's bottom edge to the bottom edge of the caller with specified inset
 *
 *  @param view  the view to constrain
 *  @param inset the inset to use when positioning the view
 */
- (NSLayoutConstraint *)constrainViewToBottom:(UIView *)view withInset:(CGFloat)inset;

/*!
 *  Constrain a view within the caller with specified insets from the edges.  Use 'NSNotFound' to specify edges that shouldn't be set
 *
 *  @param view   the view to constrain
 *  @param top    the top inset
 *  @param left   left inset
 *  @param bottom bottom inset
 *  @param right  right inset
 */
- (NSLayoutConstraint *)constrainView:(UIView *)view top:(CGFloat)top left:(CGFloat)left bottom:(CGFloat)bottom right:(CGFloat)right;

/*!
 *  Set a view's width to be equal to the caller's width
 *
 *  @param view the view to constrain
 */
- (NSLayoutConstraint *)constrainViewToEqualWidth:(UIView *)view;

/*!
 *  Set a view's width to be equal to the caller's width with a constant and multiplier option
 *
 *  @param view       the view to constrain
 *  @param constant   constant offset
 *  @param multiplier multiplier
 */
- (NSLayoutConstraint *)constrainViewToEqualWidth:(UIView *)view constant:(CGFloat)constant multiplier:(CGFloat)multiplier;

/*!
 *  Set a view's height to be equal to the caller's height
 *
 *  @param view the view to constrain
 */
- (NSLayoutConstraint *)constrainViewToEqualHeight:(UIView *)view;

/*!
 *  Set a view's height to be equal to the caller's height with a constant and multiplier option
 *
 *  @param view       the view to constrain
 *  @param constant   the constant to offset
 *  @param multiplier multiplier
 */
- (NSLayoutConstraint *)constrainViewToEqualHeight:(UIView *)view constant:(CGFloat)constant multiplier:(CGFloat)multiplier;

/*!
 *  Constrain a view to a specified width
 *
 *  @param view  the view to constrain
 *  @param width the width to constrain the view
 */
- (NSLayoutConstraint *)constrainView:(UIView *)view toWidth:(CGFloat)width;

/*!
 *  Constrain a view to a specified height
 *
 *  @param view   the view to constrain
 *  @param height the height to constrain the view
 */
- (NSLayoutConstraint *)constrainView:(UIView *)view toHeight:(CGFloat)height;

/**
 *  Constrain a view to a specified aspect ration
 *
 *  @param view        the view to constrain
 *  @param aspectRatio the aspect ratio to constrain the view
 */
- (NSLayoutConstraint *)constrainView:(UIView *)view toAspectRatio:(CGFloat)aspectRatio;

/*!
 *  Position a view above another view
 *
 *  @param view            the view to position above
 *  @param positioningView the view to use for positioning
 */
- (NSLayoutConstraint *)constrainView:(UIView *)view aboveView:(UIView *)positioningView;

/**
 *  Position a view above another view with an offset
 *
 *  @param view            the view to position above
 *  @param positioningView the view to use for positioning
 *  @param offset          the constant to offset
 */
- (NSLayoutConstraint *)constrainView:(UIView *)view aboveView:(UIView *)positioningView withOffset:(CGFloat)offset;

/*!
 *  Position a view below another view
 *
 *  @param view            the view to position below
 *  @param positioningView the view to use for positioning
 */
- (NSLayoutConstraint *)constrainView:(UIView *)view belowView:(UIView *)positioningView;

/**
 *  Position a view below another view with offset
 *
 *  @param view            the view to position below
 *  @param positioningView the view to use for positioning
 *  @param offset          the constant to offset
 */
- (NSLayoutConstraint *)constrainView:(UIView *)view belowView:(UIView *)positioningView withOffset:(CGFloat)offset;

/*!
 *  Position a view to the left of another view
 *
 *  @param view            the view to position
 *  @param positioningView the view to use for positioning
 */
- (NSLayoutConstraint *)constrainView:(UIView *)view leftOfView:(UIView *)positioningView;

/**
 *  Position a view to the left of another view with offset
 *
 *  @param view            the view to position
 *  @param positioningView the view to use for positioning
 *  @param offset          the constant to offset
 */
- (NSLayoutConstraint *)constrainView:(UIView *)view leftOfView:(UIView *)positioningView withOffset:(CGFloat)offset;

/*!
 *  Position a view to the right of another view
 *
 *  @param view            the view to position
 *  @param positioningView the view to use for positioning
 */
- (NSLayoutConstraint *)constrainView:(UIView *)view rightOfView:(UIView *)positioningView;

/**
 *  Position a view to the right of another view with offset
 *
 *  @param view            the view to position
 *  @param positioningView the view to use for positioning
 *  @param offset          the constant to offset
 */
- (NSLayoutConstraint *)constrainView:(UIView *)view rightOfView:(UIView *)positioningView withOffset:(CGFloat)offset;

/**
 *  Position two views so that their tops are aligned vertically
 *
 *  @param view            the view to position
 *  @param positioningView the view to use for positioning
 */
- (NSLayoutConstraint *)constrainView:(UIView *)view toTopOfView:(UIView *)positioningView;

/**
 *  Position two views so that their bottoms are aligned vertically
 *
 *  @param view            the view to position
 *  @param positioningView the view to use for positioning
 */
- (NSLayoutConstraint *)constrainView:(UIView *)view toBottomOfView:(UIView *)positioningView;

/**
 *  Constrain the width of two views to be equal
 *
 *  @param view       the view to constrain
 *  @param sizingView the view to use as a width reference
 */
- (NSLayoutConstraint *)constrainView:(UIView *)view toWidthOfView:(UIView *)sizingView;

/**
 *  Constrain the height of two views to be equal
 *
 *  @param view       the view to constrain
 *  @param sizingView the view to use as a height reference
 */
- (NSLayoutConstraint *)constrainView:(UIView *)view toHeightOfView:(UIView *)sizingView;

/*!
 *  More customizable control for building relationships between two views
 *
 *  @param viewA      a view to constrain
 *  @param attributeA the attribute to constrain
 *  @param viewB      the second view used in constrainint
 *  @param attributeB the attribute to constrain
 */
- (NSLayoutConstraint *)constrainView:(UIView *)viewA attribute:(NSLayoutAttribute)attributeA toView:(UIView *)viewB attribute:(NSLayoutAttribute)attributeB;

/*!
 *  More customizable control for building relationships between two views
 *
 *  @param viewA      a view to constrain
 *  @param attributeA the attribute to constrain
 *  @param viewB      the second view used in constraint
 *  @param attributeB secondary view attribute
 *  @param constant   constant
 *  @param multiplier multiplier
 */
- (NSLayoutConstraint *)constrainView:(UIView *)viewA attribute:(NSLayoutAttribute)attributeA toView:(UIView *)viewB attribute:(NSLayoutAttribute)attributeB constant:(CGFloat)constant multiplier:(CGFloat)multiplier;

/*!
 *  More customizable control for building relationships between two views
 *
 *  @param viewA      primary view to constrain
 *  @param attributeA primary attribute
 *  @param viewB      secondary view to constrain
 *  @param attributeB secondary attribute
 *  @param constant   constant
 *  @param multiplier multiplier
 *  @param relation   relation
 */
- (NSLayoutConstraint *)constrainView:(UIView *)viewA attribute:(NSLayoutAttribute)attributeA toView:(UIView *)viewB attribute:(NSLayoutAttribute)attributeB constant:(CGFloat)constant multiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation;

/*!
 *  Convenience for horizontal center
 *
 *  @param view view to constrain
 */
- (NSLayoutConstraint *)constrainViewToMiddleHorizontally:(UIView *)view;

/*!
 *  Convenience for vertical center
 *
 *  @param view view to constrain
 */
- (NSLayoutConstraint *)constrainViewToMiddleVertically:(UIView *)view;

/*!
 *  Constrain top of view to the center with specified offset
 *
 *  @param view   view to constrain
 *  @param offset the offset from centerY to top of view
 */
- (NSLayoutConstraint *)constrainTopOfView:(UIView *)view toCenterYWithOffset:(CGFloat)offset;

/*!
 *  Constrain bottom of view to the center with specified offset
 *
 *  @param view   the view to constrain
 *  @param offset the offset from centerY to bottom of view
 */
- (NSLayoutConstraint *)constrainBottomOfView:(UIView *)view toCenterYWithOffset:(CGFloat)offset;

/*!
 *  Constrain the view to 0 on all edges of caller
 *
 *  @param view the view to constrain
 */
- (ConstraintDictionary *)constrainViewToAllEdges:(UIView *)view;

/*!
 *  Constrain the left and right edges of the view to the caller
 *
 *  @param view the view to constrain
 */
- (ConstraintDictionary *)constrainViewToHorizontalEdges:(UIView *)view;

@end
