//
//  SILDictionaryPair.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/26/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SILDoubleKeyDictionaryPair : NSObject
@property (nonatomic, getter=getCount, readonly) NSUInteger count;
- (id _Nullable)objectForNameKey:(NSObject *_Nullable)nameKey;
- (id _Nullable)idForNameKey:(NSObject *_Nullable)nameKey;
- (id _Nullable)objectForIdKey:(NSObject *_Nullable)idKey;
- (void)addObject:(NSObject *_Nullable)object nameKey:(id<NSCopying>_Nonnull)nameKey idKey:(id<NSCopying>_Nonnull)idKey;
- (void)addNameKey:(id<NSCopying>_Nonnull)nameKey idKey:(id<NSCopying>_Nonnull)idKey;
- (NSArray * _Nullable)idKeys;
- (NSArray * _Nullable)namesForIdKey:(NSObject *_Nullable)idKey;
@end
