//
//  Created by merowing on 22/04/2014.
//
//
//


#import "KZBehaviour.h"
#import "objc/runtime.h"

@implementation KZBehaviour

- (void)setOwner:(id)owner
{
  if (_owner != owner) {
    [self kzc_releaseLifetimeFromObject:_owner];
    _owner = owner;
    [self kzc_bindLifetimeToObject:_owner];
  }
}


- (void)kzc_bindLifetimeToObject:(id)object
{
  objc_setAssociatedObject(object, (__bridge void *)self, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)kzc_releaseLifetimeFromObject:(id)object
{
  objc_setAssociatedObject(object, (__bridge void *)self, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end