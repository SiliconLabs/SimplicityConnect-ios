//
//  SILBluetoothDescriptorModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/19/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SILBluetoothDescriptorModel : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSString *uuidString;

- (instancetype)initWithName:(NSString *)name type:(NSString *)type uuid:(NSString *)uuidString;

@end
