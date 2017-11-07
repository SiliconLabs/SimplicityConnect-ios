//
//  SILBeaconDataViewModel.h
//  SiliconLabsApp
//
//  Created by Max Litteral on 6/22/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SILBeaconDataModel;

@interface SILBeaconDataViewModel : NSObject

@property (strong, nonatomic, readonly) NSString *valueString;
@property (strong, nonatomic, readonly) NSString *typeString;

- (instancetype)initWithBeaconDataModel:(SILBeaconDataModel *)dataModel;

@end
