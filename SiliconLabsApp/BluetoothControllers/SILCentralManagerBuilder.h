//
//  SILCentralManagerBuilder.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/14/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILApp.h"
@class SILCentralManager;

@interface SILCentralManagerBuilder : NSObject

+ (SILCentralManager *)buildCentralManagerWithAppType:(SILAppType)appType;

@end
