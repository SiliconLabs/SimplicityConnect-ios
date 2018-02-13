//
//  SILSettings.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/12/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILSettings.h"

NSString * const SILSettingsDisplayDebugValues = @"SILSettingsDisplayDebugValues";

NSString * const SILSettingsFobProximityDeltaThreshold = @"SILSettingsFobProximityDeltaThreshold";
NSString * const SILSettingsMinExpectedFobDelta = @"SILSettingsMinExpectedFobDelta";
NSString * const SILSettingsMaxExpectedFobDelta = @"SILSettingsMaxExpectedFobDelta";

NSString * const SILSettingsNearProximityThreshold = @"SILSettingsNearProximityThreshold";
NSString * const SILSettingsFarProximityThreshold = @"SILSettingsFarProximityThreshold";

@implementation SILSettings

static BOOL _displayDebugValues;

static float _fobProximityDeltaThreshold;
static float _minExpectedFobDelta;
static float _maxExpectedFobDelta;

static float _nearProximityThreshold;
static float _farProximityThreshold;

+ (void)initialize {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
                                                              SILSettingsDisplayDebugValues         : @NO,

                                                              SILSettingsFobProximityDeltaThreshold : @-2,
                                                              SILSettingsMinExpectedFobDelta        : @-22,
                                                              SILSettingsMaxExpectedFobDelta        : @18,

                                                              SILSettingsNearProximityThreshold     : @0.5,
                                                              SILSettingsFarProximityThreshold      : @1.0,
                                                              }];

    _displayDebugValues = [[NSUserDefaults standardUserDefaults] boolForKey:SILSettingsDisplayDebugValues];

    _fobProximityDeltaThreshold = [[NSUserDefaults standardUserDefaults] floatForKey:SILSettingsFobProximityDeltaThreshold];
    _minExpectedFobDelta = [[NSUserDefaults standardUserDefaults] floatForKey:SILSettingsMinExpectedFobDelta];
    _maxExpectedFobDelta = [[NSUserDefaults standardUserDefaults] floatForKey:SILSettingsMaxExpectedFobDelta];

    _nearProximityThreshold = [[NSUserDefaults standardUserDefaults] floatForKey:SILSettingsNearProximityThreshold];
    _farProximityThreshold = [[NSUserDefaults standardUserDefaults] floatForKey:SILSettingsFarProximityThreshold];
}

#pragma mark - Display Debug Values

+ (BOOL)displayDebugValues {
    return _displayDebugValues;
}

+ (void)setDisplayDebugValues:(BOOL)displayDebugValues {
    _displayDebugValues = displayDebugValues;
    [[NSUserDefaults standardUserDefaults] setBool:displayDebugValues forKey:SILSettingsDisplayDebugValues];
}

#pragma mark - Fob Values

+ (float)fobProximityDeltaThreshold {
    return _fobProximityDeltaThreshold;
}

+ (void)setFobProximityDeltaThreshold:(float)fobProximityDeltaThreshold {
    _fobProximityDeltaThreshold = fobProximityDeltaThreshold;
    [[NSUserDefaults standardUserDefaults] setFloat:fobProximityDeltaThreshold forKey:SILSettingsFobProximityDeltaThreshold];
}

+ (float)minExpectedFobDelta {
    return _minExpectedFobDelta;
}

+ (void)setMinExpectedFobDelta:(float)minExpectedFobDelta {
    _minExpectedFobDelta = minExpectedFobDelta;
    [[NSUserDefaults standardUserDefaults] setFloat:minExpectedFobDelta forKey:SILSettingsMinExpectedFobDelta];
}

+ (float)maxExpectedFobDelta {
    return _maxExpectedFobDelta;
}

+ (void)setMaxExpectedFobDelta:(float)maxExpectedFobDelta {
    _maxExpectedFobDelta = maxExpectedFobDelta;
    [[NSUserDefaults standardUserDefaults] setFloat:maxExpectedFobDelta forKey:SILSettingsMaxExpectedFobDelta];
}

#pragma mark - Proximity Values

+ (float)nearProximityThreshold {
    return _nearProximityThreshold;
}

+ (void)setNearProximityThreshold:(float)nearProximityThreshold {
    _nearProximityThreshold = nearProximityThreshold;
    [[NSUserDefaults standardUserDefaults] setFloat:nearProximityThreshold forKey:SILSettingsNearProximityThreshold];
}

+ (float)farProximityThreshold {
    return _farProximityThreshold;
}

+ (void)setFarProximityThreshold:(float)farProximityThreshold {
    _farProximityThreshold = farProximityThreshold;
    [[NSUserDefaults standardUserDefaults] setFloat:farProximityThreshold forKey:SILSettingsFarProximityThreshold];
}


@end
