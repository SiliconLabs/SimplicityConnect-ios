//
//  SILBluetoothEnumerationModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/20/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SILBluetoothEnumerationModel : NSObject

@property (nonatomic) NSInteger key;
@property (strong, nonatomic) NSString *value;
@property (strong, nonatomic) NSString *requires;

- (instancetype)initWithKey:(NSInteger)key value:(NSString *)value requires:(NSString *)requires;

@end
