//
//  SILEncodingTextField.m
//  SiliconLabsApp
//
//  Created by Grzegorz Janosz on 29/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILEncodingTextField.h"

@interface SILEncodingTextField()

@property UIView *border;

@end

@implementation SILEncodingTextField

const NSTimeInterval duration = 0.5;

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

-(void)commonInit {
    self.borderStyle = UITextBorderStyleNone;
    self.clipsToBounds = FALSE;
    
    _border = [[UILabel alloc] init];
    _border.backgroundColor = UIColor.sil_subtleTextColor;
    [_border setUserInteractionEnabled:NO];
    [self addSubview:_border];
    
    [self addTarget:self action:@selector(updateBorder) forControlEvents:UIControlEventAllEditingEvents];
}

-(void)updateBorder {
    UIColor *borderColor = self.isFirstResponder ? UIColor.sil_siliconLabsRedColor : UIColor.sil_subtleTextColor;
    [UIView animateWithDuration:duration animations:^{
        self.border.backgroundColor = borderColor;
    }];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    _border.frame = CGRectMake(0, self.bounds.size.height - 1, self.bounds.size.width, 1);
}

@end
