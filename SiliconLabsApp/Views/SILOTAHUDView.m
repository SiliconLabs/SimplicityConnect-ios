//
//  SILOTAHUDView.m
//  SiliconLabsApp
//
//  Created by Bob Gilmore on 3/22/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILOTAHUDView.h"

@implementation SILOTAHUDView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSString *className = NSStringFromClass([self class]);
        _view = [[[NSBundle mainBundle] loadNibNamed:className owner:self options:nil] firstObject];
        [self addSubview:self.view];
        _view.translatesAutoresizingMaskIntoConstraints = false;
        [self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[view]-0-|" options:NSLayoutFormatAlignAllLeft metrics:nil views:@{@"view":_view}]];
        [self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|" options:NSLayoutFormatAlignAllLeft metrics:nil views:@{@"view":_view}]];
        _uploadTypeLabel.text = @"";
        _fileNameLabel.text = @"";
        _fileTotalBytesLabel.text = @"";
        _fileCountLabel.text = @"";
    }
    return self;
}

- (void)stateDependentHidden:(BOOL)hidden {
    _stateDependentView.hidden = hidden;
    _constrainBottomSeparatorBelowFile.active = !hidden;
}

@end
