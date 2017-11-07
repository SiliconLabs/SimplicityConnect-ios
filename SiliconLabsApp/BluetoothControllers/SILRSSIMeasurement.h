//
//  SILRSSIMeasurement.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/6/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SILRSSIMeasurement : NSObject

@property (strong, nonatomic) NSNumber *RSSI;
@property (strong, nonatomic) NSDate *date;

- (instancetype)initWithRSSI:(NSNumber *)RSSI date:(NSDate *)date;

@end
