//
//  UIButton+IPUtils.h
//  Pods
//
//  Created by Ying Quan Tan on 12/24/15.
//
//

@import UIKit;

@interface UIButton (IPUtils)

/**
 *  Puts a space between the image and the text in a UIButton. Assumes that image is on the left, and text is right
 *  Taken from: http://stackoverflow.com/questions/4564621/aligning-text-and-image-on-uibutton-with-imageedgeinsets-and-titleedgeinsets
 */
- (void)centerButtonAndImageWithSpacing:(CGFloat)spacing;

@end
