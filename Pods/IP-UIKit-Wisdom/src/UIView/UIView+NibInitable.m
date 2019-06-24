#import "UIView+NibInitable.h"

#pragma clang diagnostic push
// Ignoring this warning because a call will be made to `initWithCoder:` when the nib is loaded, otherwise the function fails.
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"

@implementation UIView (NibInitable)
- (instancetype)initWithNibNamed:(NSString *)nibNameOrNil {
    if (!nibNameOrNil) {
        nibNameOrNil = NSStringFromClass([self class]);
    }
    NSArray *viewsInNib = [[NSBundle mainBundle] loadNibNamed:nibNameOrNil
                                                        owner:nil
                                                      options:nil];
    for (id view in viewsInNib) {
        if ([view isKindOfClass:[self class]]) {
            self = view;
            break;
        }
    }
    
    NSAssert(self != nil,
             @"Unable to initialize view of class: %@ from nib named: %@", [self class], nibNameOrNil);
    return self;
}
@end

#pragma clang diagnostic pop
