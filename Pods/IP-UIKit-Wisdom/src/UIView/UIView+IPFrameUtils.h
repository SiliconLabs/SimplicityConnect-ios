#import <UIKit/UIKit.h>

@interface UIView (IPFrameUtils)

/*!
 Gets and sets the view's origin. This leaves the frame's size untouched.
 */
@property (nonatomic, readwrite) CGPoint frameOrigin;

/*!
 Gets and sets the view's frame sizesize. This leaves the frame's origin untouched.
 */
@property (nonatomic, readwrite) CGSize frameSize;

/*!
 Gets and sets the view frame's x origin.
 */
@property (nonatomic, readwrite) CGFloat frameX;

/*!
 Gets and sets the view frame's y origin.
 */
@property (nonatomic, readwrite) CGFloat frameY;

/*!
 Gets and sets the view frame's width
 */
@property (nonatomic, readwrite) CGFloat frameWidth;

/*!
 Gets and sets the view frame's height
 */
@property (nonatomic, readwrite) CGFloat frameHeight;

/*!
 Gets and sets the view frame's middle x position
 */
@property (nonatomic, readwrite) CGFloat frameMidX;

/*!
 Gets and sets the view frame's middle y position
 */
@property (nonatomic, readwrite) CGFloat frameMidY;

/*!
 Gets x value of the right edge of the view's frame.
 Setting frameMaxX moves the origin of the view so that the right edge is at frameMaxX. The frame's width does not change.
 */
@property (nonatomic, readwrite) CGFloat frameMaxX;

/*!
 Gets y value of the bottom edge of the view's frame.
 Setting frameMaxY moves the origin of the view so that the bottom edge is at frameMaxY. The frame's height does not change.
 */
@property (nonatomic, readwrite) CGFloat frameMaxY;

/*!
 When adjustHeight is NO, this moves the origin of the view so that the bottom edge is at frameMaxY. The frame's height does not change.
 When adjustHeight is YES, the size of the view is changed so that the bottom edge is at frameMaxY.
 */
- (void)setFrameMaxY:(CGFloat)frameMaxY adjustHeight:(BOOL)adjustHeight;

@end
