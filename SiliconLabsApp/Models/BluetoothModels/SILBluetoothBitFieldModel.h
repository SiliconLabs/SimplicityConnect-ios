//
//  SILBluetoothBitFieldModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/20/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SILBluetoothBitFieldModel : NSObject

@property (strong, nonatomic) NSArray *bits;

- (instancetype)initWithBits:(NSArray *)bits;

@end
