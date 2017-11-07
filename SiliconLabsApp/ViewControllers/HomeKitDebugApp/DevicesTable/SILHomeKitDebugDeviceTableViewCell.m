//
//  SILHomeKitDebugDeviceTableViewCell.m
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/17/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILHomeKitDebugDeviceTableViewCell.h"
#import "UIView+SILAnimations.h"
#import "UIColor+SILColors.h"
#import "SILDebugAdvDetailsViewController.h"
#import "SILDebugAdvDetailCollectionViewCell.h"
#import "SILDebugAdvDetailsCollectionView.h"
#import "UIColor+SILColors.h"

@interface SILHomeKitDebugDeviceTableViewCell()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomHalfCollapsedHeightConstraint;
@property (weak, nonatomic) IBOutlet SILDebugAdvDetailsCollectionView *advertisementInfoCollectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *topContainerView;
@property (weak, nonatomic) IBOutlet UIView *bottomContainerView;
@property (nonatomic) BOOL isAnimating;

@end

@implementation SILHomeKitDebugDeviceTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self configureIPadCell];
    }
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(connectToDeviceTap:)];
    tapGestureRecognizer.cancelsTouchesInView = NO;
    [self.deviceNameContainer addGestureRecognizer:tapGestureRecognizer];
    self.advertisementInfoCollectionView.backgroundColor = self.bottomContainerView.backgroundColor = [UIColor sil_lightGreyColor];
    [self configureAdvInfoAsCollapsed:YES];
    NSString *cellClassName = NSStringFromClass([SILDebugAdvDetailCollectionViewCell class]);
    [self.advertisementInfoCollectionView registerNib:[UINib nibWithNibName:cellClassName bundle:nil] forCellWithReuseIdentifier:cellClassName];
    [self.advertisementInfoCollectionView reloadData];
}

#pragma mark - Configure

- (void)configureAsOwner:(id<UICollectionViewDataSource, UICollectionViewDelegate>)owner withIndexPath:(NSIndexPath *)indexPath {
    self.advertisementInfoCollectionView.parentIndexPath = indexPath;
    self.advertisementInfoCollectionView.delegate = owner;
    self.advertisementInfoCollectionView.dataSource = owner;
}

- (void)configureAsEnabled:(BOOL)enabled connectable:(BOOL)connectable {
    self.contentView.alpha = enabled ? 1 : 0.5;
    self.userInteractionEnabled = enabled;

    self.collectionViewHeightConstraint.constant = self.advertisementInfoCollectionView.contentSize.height;
    [self.advertisementInfoCollectionView setNeedsLayout];
    [self.advertisementInfoCollectionView setNeedsUpdateConstraints];
    [self.advertisementInfoCollectionView reloadData];
    
    self.connectionChevron.hidden = !connectable || self.isAnimating;
    self.deviceNameContainer.backgroundColor = connectable ? [UIColor whiteColor] : [UIColor sil_bgGreyColor];
    self.advertisementInfoCollectionView.backgroundColor = self.bottomContainerView.backgroundColor = connectable ? [UIColor sil_lightGreyColor] : [UIColor sil_bgGreyColor];
}

- (void)configureAdvInfoAsCollapsed:(BOOL)collapse {
}

- (void)revealCollectionView {
    [self layoutIfNeeded];
    [UIView animateWithDuration:0.5 animations:^{
        self.bottomHalfCollapsedHeightConstraint.priority = 1;
        self.collectionViewHeightConstraint.constant = self.advertisementInfoCollectionView.contentSize.height;
        [self layoutIfNeeded];
    }];
}

- (void)configureIPadCell {
    self.topContainerView.layer.borderColor = self.bottomContainerView.layer.borderColor = [UIColor sil_lineGreyColor].CGColor;
    self.topContainerView.layer.borderWidth = self.bottomContainerView.layer.borderWidth = 1.0f;
}


#pragma mark - IBActions

- (IBAction)didTapMoreInfo:(UIButton *)sender {
    NSLog(@"More info");
    [self.delegate displayAdverisementDetails:self];
}

#pragma mark - Actions

- (void)connectToDeviceTap:(UITapGestureRecognizer *)gesture {
    [self.delegate didTapToConnect:self];
}

#pragma mark - Animation

- (void)startConnectionAnimation {
    self.isAnimating = YES;
    self.loadingSpinnerImageView.hidden = NO;
    self.connectionChevron.hidden = YES;
    [UIView addContinuousRotationAnimationToLayer:self.loadingSpinnerImageView.layer
                         withFullRotationDuration:2
                                           forKey:@"connectingAnimation"];
}

- (void)stopConnectionAnimation {
    self.isAnimating = NO;
    self.loadingSpinnerImageView.hidden = YES;
    self.connectionChevron.hidden = NO;
    [self.loadingSpinnerImageView.layer removeAllAnimations];
}

@end
