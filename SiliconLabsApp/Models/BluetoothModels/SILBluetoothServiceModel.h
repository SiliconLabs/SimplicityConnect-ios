//
//  SILBluetoothServiceModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/19/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SILBluetoothServiceModel : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *summary;
@property (strong, nonatomic) NSString *uuidString;
@property (strong, nonatomic) NSArray *serviceCharacteristics;

- (instancetype)initWithName:(NSString *)name summary:(NSString *)summary uuid:(NSString *)uuid;

@end
