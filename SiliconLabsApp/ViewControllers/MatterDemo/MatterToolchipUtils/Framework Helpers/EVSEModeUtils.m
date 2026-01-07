//
//  EVSEModeUtils.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 21/09/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

#import "EVSEModeUtils.h"

@implementation EVSEModeUtils

+ (NSString *)modeNameForModeValue:(NSNumber *)modeValue fromSupportedModes:(NSArray *)supportedModes {
    if (!modeValue || !supportedModes.count) {
        return modeValue ? modeValue.stringValue : @"-";
    }

    for (id entry in supportedModes) {
        // Case 1: Generated Matter struct style (KVC accessible: mode / label)
        if ([entry respondsToSelector:@selector(valueForKey:)]) {
            id modeField = nil;
            id labelField = nil;

            @try {
                modeField = [entry valueForKey:@"mode"];   // common field name
                if (!modeField) {
                    modeField = [entry valueForKey:@"value"]; // fallback (some clusters use value)
                }
                labelField = [entry valueForKey:@"label"]; // common label field
                if (!labelField) {
                    labelField = [entry valueForKey:@"name"]; // fallback
                }
            } @catch (NSException * _) {
                modeField = nil;
                labelField = nil;
            }

            if ([modeField isKindOfClass:[NSNumber class]] &&
                [labelField isKindOfClass:[NSString class]] &&
                [modeField isEqualToNumber:modeValue]) {
                return labelField;
            }
        }

        // Case 2: Dictionary representation
        if ([entry isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = (NSDictionary *)entry;
            NSNumber *m = dict[@"mode"] ?: dict[@"value"];
            NSString *lbl = dict[@"label"] ?: dict[@"name"];
            if ([m isKindOfClass:[NSNumber class]] &&
                [lbl isKindOfClass:[NSString class]] &&
                [m isEqualToNumber:modeValue]) {
                return lbl;
            }
        }
    }

    return modeValue.stringValue; // Fallback: show numeric value
}

@end
