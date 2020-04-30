//
//  SILGenericAttributeTableModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/6/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SILGenericAttributeTableModel <NSObject>

@property (nonatomic) BOOL isExpanded;
@property (nonatomic) BOOL hideTopSeparator;

- (BOOL)canExpand;
- (void)toggleExpansionIfAllowed;
- (NSString *)uuidString;
- (NSString *)hexUuidString;
- (NSString *)name;

@end
