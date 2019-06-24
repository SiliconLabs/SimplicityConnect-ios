//
//  CAGradientLayer+IPGradients.h
//  IP-UIKit-Wisdom
//
//  Created by Nicholas Servidio on 10/26/15.
//  Copyright © 2015 Nick Servidio. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CAGradientLayer (IPGradients)

/**
 *  Creates and returns a gradient layer by blending the specified colors
 *
 *  @param topColor    This color is 100% visible at the top of the layer and 0% at the bottom of the layer
 *  @param bottomColor This color is 100% visible at the bottom of the layer and 0% at the top of the layer
 *
 *  @return The new gradient layer
 */
+ (CAGradientLayer *)gradentLayerWithTopColor:(UIColor *)topColor bottomColor:(UIColor *)bottomColor;

@end
