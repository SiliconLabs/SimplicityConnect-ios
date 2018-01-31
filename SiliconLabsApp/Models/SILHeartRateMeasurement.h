//
//  SILHeartRateMeasurement.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/15/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SILHeartRateMeasurement : NSObject

@property (strong, nonatomic) NSDate *measurementDate;
@property (assign, nonatomic) NSInteger beatsPerMinute;

@end
