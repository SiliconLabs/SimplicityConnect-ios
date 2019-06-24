#import "UIColor+IPRandomColor.h"

@implementation UIColor (IPRandomColor)

+ (UIColor *)randomColor {
    return [UIColor colorWithRed:(arc4random_uniform(255) / 255.0)
                           green:(arc4random_uniform(255) / 255.0)
                            blue:(arc4random_uniform(255) / 255.0)
                           alpha:1];
}

@end
