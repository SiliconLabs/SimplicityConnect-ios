//
//  SILSettings.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/12/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SILSettings : NSObject

+ (BOOL)displayDebugValues;
+ (void)setDisplayDebugValues:(BOOL)displayDebugValues;

+ (float)fobProximityDeltaThreshold;
+ (void)setFobProximityDeltaThreshold:(float)fobProximityDeltaThreshold;

+ (float)minExpectedFobDelta;
+ (void)setMinExpectedFobDelta:(float)minExpectedFobDelta;

+ (float)maxExpectedFobDelta;
+ (void)setMaxExpectedFobDelta:(float)maxExpectedFobDelta;

+ (float)nearProximityThreshold;
+ (void)setNearProximityThreshold:(float)nearProximityThreshold;

+ (float)farProximityThreshold;
+ (void)setFarProximityThreshold:(float)farProximityThreshold;

@end
