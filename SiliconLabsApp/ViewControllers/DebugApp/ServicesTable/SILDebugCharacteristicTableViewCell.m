//
//  SILDebugCharacteristicTableViewCell.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/7/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDebugCharacteristicTableViewCell.h"
#import "SILDebugCharacteristicPropertyView.h"
#import "UIColor+SILColors.h"
#import "SILCharacteristicTableModel.h"
#import "SILBluetoothCharacteristicModel.h"
#import "UIView+NibInitable.h"
#if ENABLE_HOMEKIT
#import "SILHomeKitCharacteristicTableModel.h"
#endif

static CGFloat characteristicProperyViewWidth = 30.0;

@interface SILDebugCharacteristicTableViewCell()
@property (weak, nonatomic) IBOutlet UIView *topSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *propertiesContainerView;
@property (weak, nonatomic) IBOutlet UIStackView *propertyButtonsStackView;
@property (weak, nonatomic) IBOutlet UILabel *characteristicNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *characteristicUuidLabel;
@property (weak, nonatomic) IBOutlet UIImageView *viewMoreChevron;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *iPadBottomDividerLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *propertyButtonsStackViewWidthConstraint;

@property (weak, nonatomic) IBOutlet UIView *readPropertyView;
@property (weak, nonatomic) IBOutlet UIView *writePropertyView;
@property (weak, nonatomic) IBOutlet UIView *writeNoResponsePropertyView;
@property (weak, nonatomic) IBOutlet UIView *indicatePropertyView;
@property (weak, nonatomic) IBOutlet UIView *notifyPropertyView;
@property (weak, nonatomic) IBOutlet UIImageView *readImageView;
@property (weak, nonatomic) IBOutlet UIImageView *writeImageView;
@property (weak, nonatomic) IBOutlet UIImageView *writeNoResponseImageView;
@property (weak, nonatomic) IBOutlet UIImageView *indicateImageView;
@property (weak, nonatomic) IBOutlet UIImageView *notifyImageView;
@property (weak, nonatomic) IBOutlet UIButton *readPropertyButton;
@property (weak, nonatomic) IBOutlet UIButton *writePropertyButton;
@property (weak, nonatomic) IBOutlet UIButton *writeNoResponsePropertyButton;
@property (weak, nonatomic) IBOutlet UIButton *notifyPropertyButton;
@property (weak, nonatomic) IBOutlet UIButton *indicatePropertyButton;

@property (strong, nonatomic) NSArray *allPropertyViews;
@property (strong, nonatomic) NSArray *allActiveProperties;

@property (strong, nonatomic) CBCharacteristic *characteristic;

@end

@implementation SILDebugCharacteristicTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor sil_lightGreyColor];
    self.allPropertyViews = @[self.readPropertyView, self.writePropertyView, self.writeNoResponsePropertyView, self.indicatePropertyView, self.notifyPropertyView];
}

- (void)configureWithCharacteristicModel:(SILCharacteristicTableModel *)characteristicModel {
    [self updateChevronImageForExpanded:characteristicModel.isExpanded];
    self.characteristicTableModel = characteristicModel;
    self.characteristic = characteristicModel.characteristic;
    self.characteristicNameLabel.text = [characteristicModel name];
    self.characteristicUuidLabel.text = [characteristicModel uuidString] ?: @"";
    self.topSeparatorView.hidden = characteristicModel.hideTopSeparator;
    [self configureAsExpandable:[characteristicModel canExpand] || [characteristicModel isUnknown]];
    self.allActiveProperties = [SILDebugProperty getActivePropertiesFrom:characteristicModel.characteristic.properties];
    [self configurePropertyViewsForProperties:self.allActiveProperties];
    [self togglePropertyEnabledIfExpanded];
    [self layoutIfNeeded];
}

#if ENABLE_HOMEKIT
- (void)configureWithHomeKitCharacteristicModel:(SILHomeKitCharacteristicTableModel *)homeKitCharacteristicModel {
    self.characteristicNameLabel.text = homeKitCharacteristicModel.name ?: @"Unknown Characteristic";
    self.characteristicUuidLabel.text = [homeKitCharacteristicModel uuidString] ?: @"";
    self.topSeparatorView.hidden = homeKitCharacteristicModel.hideTopSeparator;
    [self.propertiesContainerView setAlpha:0.0];
    self.propertyButtonsStackViewWidthConstraint.constant = 0.0;
    [self configureAsExpandable:NO];
}
#endif

- (void)configureAsExpandable:(BOOL)canExpand {
    self.viewMoreChevron.hidden = !canExpand;
}

- (void)configurePropertyViewsForProperties:(NSArray *)properties {
    [self layoutIfNeeded];

    for (UIView *view in self.allPropertyViews) {
        [view setHidden:YES];
    }
    int activePropertiesCount = 0;
    BOOL hasWriteProperty = false;
    for (SILDebugProperty *property in properties) {
        id propertyKey = property.keysForActivation.firstObject;
        if ([propertyKey isEqual:@(CBCharacteristicPropertyRead)]) {
            activePropertiesCount += 1;
            [self.readPropertyView setHidden:NO];
            [self.readPropertyButton setHidden:NO];

            self.readPropertyButton.frame = CGRectMake(0, 0, self.readImageView.frame.size.width + 25, self.readImageView.frame.size.height + 25);
            self.readPropertyButton.center = [self.contentView convertPoint:self.readPropertyView.center fromView:self.propertyButtonsStackView];
        } else if ([propertyKey isEqual:@(CBCharacteristicPropertyWrite)]) {
            activePropertiesCount += 1;
            hasWriteProperty = true;
            [self.writePropertyView setHidden:NO];
            [self.writePropertyButton setHidden:NO];

            self.writePropertyButton.frame = CGRectMake(0, 0, self.writeImageView.frame.size.width + 25, self.writeImageView.frame.size.height + 25);
            self.writePropertyButton.center = [self.contentView convertPoint:self.writePropertyView.center fromView:self.propertyButtonsStackView];
        } else if ([propertyKey isEqual:@(CBCharacteristicPropertyWriteWithoutResponse)]) {
            if (!hasWriteProperty) {
                activePropertiesCount += 1;
                [self.writeNoResponsePropertyView setHidden:NO];
                [self.writeNoResponsePropertyButton setHidden:NO];

                self.writeNoResponsePropertyButton.frame = CGRectMake(0, 0, self.writeNoResponsePropertyButton.frame.size.width + 25, self.writeNoResponsePropertyButton.frame.size.height + 25);
                self.writeNoResponsePropertyButton.center = [self.contentView convertPoint:self.writeNoResponsePropertyView.center fromView:self.propertyButtonsStackView];
            }
        } else if ([propertyKey isEqual:@(CBCharacteristicPropertyIndicate)]) {
            activePropertiesCount += 1;
            [self.indicatePropertyView setHidden:NO];
            [self.indicatePropertyButton setHidden:NO];
            
            self.indicatePropertyButton.frame = CGRectMake(0, 0, self.indicateImageView.frame.size.width + 25, self.indicateImageView.frame.size.height + 25);
            self.indicatePropertyButton.center = [self.contentView convertPoint:self.indicatePropertyView.center fromView:self.propertyButtonsStackView];
        } else if ([propertyKey isEqual:@(CBCharacteristicPropertyNotify)]) {
            activePropertiesCount += 1;
            [self.notifyPropertyView setHidden:NO];
            [self.notifyPropertyButton setHidden:NO];

            self.notifyPropertyButton.frame = CGRectMake(0, 0, self.notifyImageView.frame.size.width + 25, self.notifyImageView.frame.size.height + 25);
            self.notifyPropertyButton.center = [self.contentView convertPoint:self.notifyPropertyView.center fromView:self.propertyButtonsStackView];
        }
    }
    CGFloat cumulativeWidthOfButtons = (CGFloat)(characteristicProperyViewWidth * activePropertiesCount);
    CGFloat cumulativeWidthOfSpacing = (CGFloat)(self.propertyButtonsStackView.spacing * (MAX(activePropertiesCount, 1) - 1));
    self.propertyButtonsStackViewWidthConstraint.constant = cumulativeWidthOfButtons + cumulativeWidthOfSpacing;
}

#pragma mark - SILGenericAttributeTableCell

- (void)expandIfAllowed:(BOOL)isExpanding {
    [self togglePropertyEnabledIfExpanded];
    [self updateChevronImageForExpanded:isExpanding];
}

- (void)updateChevronImageForExpanded:(BOOL)expanded {
    self.viewMoreChevron.image = [UIImage imageNamed: expanded ? @"chevron_expanded" : @"chevron_collapsed"];
}

- (void)togglePropertyEnabledIfExpanded {
    BOOL expanded = self.characteristicTableModel.isExpanded;
    BOOL isNotifying = [[self.characteristic valueForKey:@"notifying"] boolValue];
    for (SILDebugProperty *property in self.allActiveProperties) {
        if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyRead)]) {
            NSString *readImageString = expanded ? @"PropertyReadEnabled" : @"PropertyReadDisabled";
            self.readImageView.image = [UIImage imageNamed:readImageString];
            [self.readPropertyView setUserInteractionEnabled:expanded];
            [self.readPropertyButton setUserInteractionEnabled:expanded];
        } else if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyWrite)]) {
            NSString *writeImageString = expanded ? @"PropertyWriteEnabled" : @"PropertyWriteDisabled";
            self.writeImageView.image = [UIImage imageNamed:writeImageString];
            [self.writePropertyView setUserInteractionEnabled:expanded];
            [self.writePropertyButton setUserInteractionEnabled:expanded];
        } else if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyWriteWithoutResponse)]) {
            NSString *writeImageString = expanded ? @"PropertyWriteNoResponseEnabled" : @"PropertyWriteNoResponseDisabled";
            self.writeNoResponseImageView.image = [UIImage imageNamed:writeImageString];
            [self.writeImageView setUserInteractionEnabled:expanded];
            [self.writeNoResponsePropertyButton setUserInteractionEnabled:expanded];
        } else if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyIndicate)]) {
            NSString *indicateImageString = (expanded && isNotifying) ? @"PropertyIndicateEnabled" : @"PropertyIndicateDisabled";
            self.indicateImageView.image = [UIImage imageNamed:indicateImageString];
            [self.indicatePropertyView setUserInteractionEnabled:expanded];
            [self.indicatePropertyButton setUserInteractionEnabled:expanded];
        } else if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyNotify)]) {
            NSString *notifyImageString = (expanded && isNotifying) ? @"PropertyNotifyEnabled" : @"PropertyNotifyDisabled";
            self.notifyImageView.image = [UIImage imageNamed:notifyImageString];
            [self.notifyPropertyView setUserInteractionEnabled:expanded];
            [self.notifyPropertyButton setUserInteractionEnabled:expanded];
        }
    }
}

#pragma mark - Button Actions

- (IBAction)handleReadViewTap:(id)sender {
 [self.delegate cell:self didRequestReadForCharacteristic:self.characteristic];
}

- (IBAction)handleWriteViewTap:(id)sender {
    [self.delegate cell:self didRequestWriteForCharacteristic:self.characteristic];
}

- (IBAction)handleWriteNoResponseViewTap:(id)sender {
    [self.delegate cell:self didRequestWriteNoResponseForCharacteristic:self.characteristic];
}

- (IBAction)handleIndicateViewTap:(id)sender {
    BOOL newNotifyingValue = ![[self.characteristic valueForKey:@"notifying"] boolValue];
    [self.delegate cell:self didRequestIndicateForCharacteristic:self.characteristic withValue:newNotifyingValue];
    NSString *notifyImageString = newNotifyingValue ? @"PropertyIndicateEnabled" : @"PropertyIndicateDisabled";
    self.indicateImageView.image = [UIImage imageNamed:notifyImageString];
}

- (IBAction)handleNotifyViewTap:(id)sender {
    BOOL newNotifyingValue = ![[self.characteristic valueForKey:@"notifying"] boolValue];
    [self.delegate cell:self didRequestNotifyForCharacteristic:self.characteristic withValue:newNotifyingValue];
    NSString *notifyImageString = newNotifyingValue ? @"PropertyNotifyEnabled" : @"PropertyNotifyDisabled";
    self.notifyImageView.image = [UIImage imageNamed:notifyImageString];
}

@end
