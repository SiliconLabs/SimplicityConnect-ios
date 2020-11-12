//
//  SILShadowView.m
//  BlueGecko
//
//  Created by Grzegorz Janosz on 02/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILShadowView.h"
#import "UIView+SILShadow.h"

@implementation SILShadowView

-(void)awakeFromNib {
    [super awakeFromNib];
    [self addShadow];
}

@end
