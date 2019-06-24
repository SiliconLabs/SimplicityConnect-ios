@import UIKit;

@interface UIImage (ColorMaskedImage)

/*!
 *  Used for masking the specified image to a specific color
 *
 *  @param color the color to mask to
 *
 *  @return the image that has been updated to use the specified color
 */
- (UIImage *)maskToColor:(UIColor *)color;

@end
