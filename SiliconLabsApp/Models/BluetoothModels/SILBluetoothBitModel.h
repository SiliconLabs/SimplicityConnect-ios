//
//  SILBluetoothBitModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/20/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SILBluetoothBitModel : NSObject

@property (nonatomic) NSInteger index;
@property (nonatomic) NSInteger size;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSArray *enumerations;

- (instancetype)initWithName:(NSString *)name index:(NSInteger)index size:(NSInteger)size;

@end
