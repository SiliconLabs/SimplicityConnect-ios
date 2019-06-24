#import "UIView+IPFrameUtils.h"

@implementation UIView (IPFrameUtils)

- (CGPoint)frameOrigin {
    return self.frame.origin;
}

- (void)setFrameOrigin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGSize)frameSize {
    return self.frame.size;
}

- (void)setFrameSize:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

- (CGFloat)frameX {
    return CGRectGetMinX(self.frame);
}

- (void)setFrameX:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)frameY {
    return CGRectGetMinY(self.frame);
}

- (void)setFrameY:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)frameWidth {
    return CGRectGetWidth(self.frame);
}

- (void)setFrameWidth:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)frameHeight {
    return CGRectGetHeight(self.frame);
}

- (void)setFrameHeight:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)frameMaxX {
    return CGRectGetMaxX(self.frame);
}

- (void)setFrameMaxX:(CGFloat)maxX {
    CGRect frame = self.frame;
    frame.origin.x = maxX - self.frameWidth;
    self.frame = frame;
}

- (CGFloat)frameMaxY {
    return CGRectGetMaxY(self.frame);
}

- (void)setFrameMaxY:(CGFloat)maxY {
    [self setFrameMaxY:maxY adjustHeight:NO];
}

- (CGFloat)frameMidX {
    return CGRectGetMidX(self.frame);
}

- (void)setFrameMidX:(CGFloat)midX {
    [self setFrameX:midX - floor(self.frameWidth/2)];
}

- (CGFloat)frameMidY {
    return CGRectGetMidY(self.frame);
}

- (void)setFrameMidY:(CGFloat)midY {
    [self setFrameY:midY - floor(self.frameHeight/2)];
}

- (void)setFrameMaxY:(CGFloat)frameMaxY adjustHeight:(BOOL)adjustHeight {
    CGRect frame = self.frame;
    BOOL maxYGreaterThanOriginY = frameMaxY > self.frameY;
    if (adjustHeight && maxYGreaterThanOriginY)
    {
        frame.size.height = frameMaxY - self.frameY;
    }
    else
    {
        frame.origin.y = frameMaxY - self.frameHeight;
    }
    self.frame = frame;

}

@end

