//
//  SILAdvertisementDataViewModel.h
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/2/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILAdvertisementDataModel.h"

@interface SILAdvertisementDataViewModel : NSObject

@property (strong, nonatomic, readonly) NSString *valueString;
@property (strong, nonatomic, readonly) NSString *typeString;

- (instancetype)initWithAdvertisementDataModel:(SILAdvertisementDataModel *)dataModel;

@end
