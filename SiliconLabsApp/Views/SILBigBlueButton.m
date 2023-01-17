//
//  SILBigBlueButton.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/17/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILBigBlueButton.h"
#import "UIColor+SILColors.h"

static CGFloat const kSILBigRedButtonDisabledHighlightedOpacity = 0.26;

@implementation SILBigBlueButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.backgroundColor = [UIColor sil_regularBlueColor];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor colorWithWhite:0 alpha:kSILBigRedButtonDisabledHighlightedOpacity]
               forState:UIControlStateDisabled];
    [self setTitleColor:[UIColor colorWithWhite:0 alpha:kSILBigRedButtonDisabledHighlightedOpacity]
               forState:UIControlStateHighlighted];
}

@end
