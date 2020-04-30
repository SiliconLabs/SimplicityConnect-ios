//
//  SILAdvertisementDataModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/15/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AdModelType) {
    AdModelTypeUUID,
    AdModelTypeServiceUUID,
    AdModelTypeName,
    AdModelTypePower,
    AdModelTypeMajor,
    AdModelTypeMinor
};

@interface SILAdvertisementDataModel : NSObject

@property (strong, nonatomic) NSString *value;
@property (nonatomic) AdModelType type;

- (instancetype)initWithValue:(NSString *)value type:(AdModelType)type;

@end
