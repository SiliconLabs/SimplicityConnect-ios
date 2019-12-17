//
//  SILBluetoothFieldModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/20/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SILBluetoothBitFieldModel;

@interface SILBluetoothFieldModel : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *unit;
@property (strong, nonatomic) NSString *format;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSString *requirement;
@property (strong, nonatomic) NSString *reference;
@property (nonatomic) NSInteger minimum;
@property (nonatomic) NSInteger maximum;
@property (strong, nonatomic) NSArray *enumerations;
@property (nonatomic) NSInteger decimalExponent;
@property (strong, nonatomic) SILBluetoothBitFieldModel *bitfield;

- (instancetype)initWithName:(NSString *)name unit:(NSString *)unit format:(NSString *)format requires:(NSString *)requirement;

@end
