//
//  SILAttributeTableModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/6/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILGenericAttributeTableModel.h"

@class CBDescriptor;

@interface SILDescriptorTableModel : NSObject <SILGenericAttributeTableModel>

@property (strong, nonatomic) CBDescriptor *descriptor;

- (instancetype)initWithDescriptor:(CBDescriptor *)descriptor;

@end
