//
//  CAGradientLayer+IPGradients.m
//  IP-UIKit-Wisdom
//
//  Created by Nicholas Servidio on 10/26/15.
//  Copyright © 2015 Nick Servidio. All rights reserved.
//

#import "CAGradientLayer+IPGradients.h"

@implementation CAGradientLayer (IPGradients)

+ (CAGradientLayer *)gradentLayerWithTopColor:(UIColor *)topColor bottomColor:(UIColor *)bottomColor {
    NSArray *gradientColors = @[(id)topColor.CGColor, (id)bottomColor.CGColor];
    NSArray *gradientLocations = @[@0.0, @1.0];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;
    
    return gradientLayer;
}

@end
