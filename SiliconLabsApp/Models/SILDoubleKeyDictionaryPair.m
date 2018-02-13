//
//  SILDictionaryPair.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/26/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDoubleKeyDictionaryPair.h"

@interface SILDoubleKeyDictionaryPair()
@property (strong, nonatomic) NSMutableDictionary *nameDictionary; //maps names -> ids
@property (strong, nonatomic) NSMutableDictionary *idDictionary; //maps ids -> objects
@property (strong, nonatomic) NSMutableDictionary *idAssignedNamesDictionary; //maps ids -> [array of names], so the association goes both ways
@end

@implementation SILDoubleKeyDictionaryPair

- (instancetype)init {
    self = [super  init];
    if (self) {
        self.nameDictionary = [NSMutableDictionary new];
        self.idDictionary = [NSMutableDictionary new];
        self.idAssignedNamesDictionary = [NSMutableDictionary new];
    }
    return self;
}

- (id)objectForIdKey:(id)idKey {
    return self.idDictionary[idKey];
}

- (id)objectForNameKey:(id)nameKey {
    return self.idDictionary[self.nameDictionary[nameKey]];
}

- (id)idForNameKey:(NSObject *)nameKey {
    return self.idDictionary[nameKey];
}

- (void)addObject:(NSObject *)object nameKey:(id<NSCopying>_Nonnull)nameKey idKey:(id<NSCopying>_Nonnull)idKey {
    self.nameDictionary[nameKey] = idKey;
    self.idDictionary[idKey] = object;
    [self addNameKey:nameKey idKey:idKey];
}

- (void)addNameKey:(id<NSCopying>_Nonnull)nameKey idKey:(id<NSCopying>_Nonnull)idKey {
    if (!self.idAssignedNamesDictionary[idKey]) {
        self.idAssignedNamesDictionary[idKey] = [NSMutableArray new];
    }
    if (![self.idAssignedNamesDictionary[idKey] containsObject:nameKey]) {
        [self.idAssignedNamesDictionary[idKey] addObject:nameKey];
    }
}

- (NSArray *)namesForIdKey:(NSObject *)idKey {
    return self.idAssignedNamesDictionary[idKey];
}

- (NSUInteger)getCount {
    return self.idDictionary.count;
}

- (NSArray *)idKeys {
    return [self.idDictionary allKeys];
}

@end
