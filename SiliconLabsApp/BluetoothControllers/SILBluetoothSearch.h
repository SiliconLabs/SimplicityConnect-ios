//
//  SILBluetoothSearch.h
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/17/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//  Test commit for verify write access

#import <Foundation/Foundation.h>

@class CBCentralManager;

@interface SILBluetoothSearch : NSObject

- (instancetype)initWithCentralManager:(CBCentralManager *)centralManager;
- (void)searchForService:(NSString *)serviceName completionHandler:(void (^)(CBPeripheral *peripheral))completion;

@end
