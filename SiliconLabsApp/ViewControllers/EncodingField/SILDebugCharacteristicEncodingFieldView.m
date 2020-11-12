//
//  SILDebugCharacteristicEncodingFieldView.m
//  SiliconLabsApp
//
//  Created by Grzegorz Janosz on 30/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILDebugCharacteristicEncodingFieldView.h"

@interface SILDebugCharacteristicEncodingFieldView()

@property (strong, nonatomic) IBOutlet UIView *contentView;

@end

@implementation SILDebugCharacteristicEncodingFieldView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

-(void)layoutSubviews {
    self.contentView.frame = self.bounds;
}

- (void)commonInit {
    [[NSBundle mainBundle] loadNibNamed:@"SILDebugCharacteristicEncodingFieldView" owner:self options:nil];
    [self addSubview:self.contentView];
}

- (IBAction)copyButtonClicked:(id)sender {
    UIPasteboard * pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.valueLabel.text;
    [self.delegate copyButtonWasClicked];
}

@end
