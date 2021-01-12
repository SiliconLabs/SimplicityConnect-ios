//
//  NSObject+SILAssociatedObject.m
//  BlueGecko
//
//  Created by Michal Lenart on 03/12/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "NSObject+SILAssociatedObject.h"

static void* const kSILAssociatedObjectsKey = (void*)&kSILAssociatedObjectsKey;

@implementation NSObject(SILAssociatedObject)

- (nullable id)sil_associatedObject:(NSString*)key {
    NSDictionary* objects = objc_getAssociatedObject(self, kSILAssociatedObjectsKey);
    return [objects valueForKey:key];
}

- (void)sil_setAssociatedObject:(nullable id)object forKey:(NSString*)key {
    NSMutableDictionary* objects = objc_getAssociatedObject(self, kSILAssociatedObjectsKey);
    
    if (objects == nil) {
        objects = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, kSILAssociatedObjectsKey, objects, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    [objects setValue:object forKey:key];
}

@end
