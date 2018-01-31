//
//  SILDebugCharacteristicPropertyLabelViewController.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/8/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDebugCharacteristicPropertyView.h"
#import "SILDebugProperty.h"

@interface SILDebugCharacteristicPropertyView ()

@end

@implementation SILDebugCharacteristicPropertyView

+ (void)addProperties:(NSArray *)properties toContainerView:(UIView *)containerView {
    SILDebugCharacteristicPropertyView *preceedingView;
    SILDebugCharacteristicPropertyView *propertyView;
    NSMutableDictionary *viewsDictionary = [[NSMutableDictionary alloc] init];
    [containerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    for (SILDebugProperty *propertyModel in properties) {
        propertyView = [[SILDebugCharacteristicPropertyView alloc] initWithPropertyModel:propertyModel];
        [containerView addSubview:propertyView];
        viewsDictionary[@"view"] = propertyView;
        propertyView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:viewsDictionary]];
        
        if (!preceedingView) {
            [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view(15)]" options:0 metrics:nil views:viewsDictionary]];
        } else {
            [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[preceeding]-5-[view(15)]" options:0 metrics:nil views:viewsDictionary]];
        }
        preceedingView = propertyView;
        viewsDictionary[@"preceeding"] = preceedingView;
    }
    [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[preceeding]->=0-|" options:0 metrics:nil views:viewsDictionary]];
    [containerView layoutIfNeeded];
}

- (instancetype)initWithPropertyModel:(SILDebugProperty *)propertyModel {
    self = [super init];
    if (self) {
        NSString *nibName = NSStringFromClass([self class]);
        UINib *nib = [UINib nibWithNibName:nibName bundle:nil];
        self = [[nib instantiateWithOwner:self options:nil] objectAtIndex:0];
        [self configureForPropertyModel:propertyModel];
    }
    return self;
}

- (void)configureForPropertyModel:(SILDebugProperty *)propertyModel {
    self.propertyTitleLabel.text = propertyModel.title;
    if (propertyModel.imageName) {
        self.propertyIconImageView.image = [UIImage imageNamed:propertyModel.imageName];
    }
    [self layoutIfNeeded];
}

@end
