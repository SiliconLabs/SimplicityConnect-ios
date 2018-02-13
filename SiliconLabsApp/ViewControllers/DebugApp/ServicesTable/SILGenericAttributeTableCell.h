//
//  SILGenericAttributeTableCell.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/7/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SILGenericAttributeTableCell <NSObject>

- (void)expandIfAllowed:(BOOL)isExpanding;

@end
