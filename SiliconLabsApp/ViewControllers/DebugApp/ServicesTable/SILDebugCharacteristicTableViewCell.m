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
@property (weak, nonatomic) IBOutlet UIButton *readButton;
@property (weak, nonatomic) IBOutlet UIButton *writeButton;
@property (weak, nonatomic) IBOutlet UIButton *indicateButton;
@property (weak, nonatomic) IBOutlet UIButton *notifyButton;
@property (weak, nonatomic) IBOutlet UIButton *writeNoResponseButton;
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
    for (UIView *view in self.allPropertyViews) {
        [view setHidden:YES];
    }
    int activePropertiesCount = 0;
    BOOL hasWriteProperty = false;
    for (SILDebugProperty *property in properties) {
        id propertyKey = property.keysForActivation.firstObject;
        if ([propertyKey isEqual:@(CBCharacteristicPropertyRead)]) {
            [self.readPropertyView setHidden:NO];
            activePropertiesCount += 1;
        } else if ([propertyKey isEqual:@(CBCharacteristicPropertyWrite)]) {
            hasWriteProperty = true;
            [self.writePropertyView setHidden:NO];
            activePropertiesCount += 1;
        } else if ([propertyKey isEqual:@(CBCharacteristicPropertyWriteWithoutResponse)]) {
            if (!hasWriteProperty) {
                [self.writeNoResponsePropertyView setHidden:NO];
                activePropertiesCount += 1;
            }
        } else if ([propertyKey isEqual:@(CBCharacteristicPropertyIndicate)]) {
            [self.indicatePropertyView setHidden:NO];
            activePropertiesCount += 1;
        } else if ([propertyKey isEqual:@(CBCharacteristicPropertyNotify)]) {
            [self.notifyPropertyView setHidden:NO];
            activePropertiesCount += 1;
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

-(void)togglePropertyEnabledIfExpanded {
    BOOL expanded = self.characteristicTableModel.isExpanded;
    BOOL isNotifying = [[self.characteristic valueForKey:@"notifying"] boolValue];
    for (SILDebugProperty *property in self.allActiveProperties) {
        if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyRead)]) {
            NSString *readImageString = expanded ? @"PropertyReadEnabled" : @"PropertyReadDisabled";
            [self.readButton setBackgroundImage:[UIImage imageNamed:readImageString] forState:UIControlStateNormal];
            [self.readButton setEnabled:expanded];
        } else if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyWrite)]) {
            NSString *writeImageString = expanded ? @"PropertyWriteEnabled" : @"PropertyWriteDisabled";
            [self.writeButton setBackgroundImage:[UIImage imageNamed:writeImageString] forState:UIControlStateNormal];
            [self.writeButton setEnabled: expanded];
        } else if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyWriteWithoutResponse)]) {
            NSString *writeImageString = expanded ? @"PropertyWriteNoResponseEnabled" : @"PropertyWriteNoResponseDisabled";
            [self.writeNoResponseButton setBackgroundImage:[UIImage imageNamed:writeImageString] forState:UIControlStateNormal];
            [self.writeNoResponseButton setEnabled:expanded];
        } else if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyIndicate)]) {
            NSString *indicateImageString = (expanded && isNotifying) ? @"PropertyIndicateEnabled" : @"PropertyIndicateDisabled";
            [self.indicateButton setBackgroundImage:[UIImage imageNamed:indicateImageString] forState:UIControlStateNormal];
            [self.indicateButton setEnabled:expanded];
        } else if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyNotify)]) {
            NSString *notifyImageString = (expanded && isNotifying) ? @"PropertyNotifyEnabled" : @"PropertyNotifyDisabled";
            [self.notifyButton setBackgroundImage:[UIImage imageNamed:notifyImageString] forState:UIControlStateNormal];
            [self.notifyButton setEnabled:expanded];
        }
    }
}

#pragma mark - Button Actions

- (IBAction)didTapReadButton:(UIButton *)sender {
    [self.delegate cell:self didRequestReadForCharacteristic:self.characteristic];
}

- (IBAction)didTapWriteButton:(UIButton *)sender {
    [self.delegate cell:self didRequestWriteForCharacteristic:self.characteristic];
}

- (IBAction)didTapWriteNoResponseButton:(UIButton *)sender {
    [self.delegate cell:self didRequestWriteNoResponseForCharacteristic:self.characteristic];
}

- (IBAction)didTapIndicateButton:(UIButton *)sender {
    BOOL newNotifyingValue = ![[self.characteristic valueForKey:@"notifying"] boolValue];
    [self.delegate cell:self didRequestIndicateForCharacteristic:self.characteristic withValue:newNotifyingValue];
    NSString *notifyImageString = newNotifyingValue ? @"PropertyIndicateEnabled" : @"PropertyIndicateDisabled";
    [self.indicateButton setBackgroundImage:[UIImage imageNamed:notifyImageString] forState:UIControlStateNormal];
}

- (IBAction)didTapNotifyButton:(UIButton *)sender {
    BOOL newNotifyingValue = ![[self.characteristic valueForKey:@"notifying"] boolValue];
    [self.delegate cell:self didRequestNotifyForCharacteristic:self.characteristic withValue:newNotifyingValue];
    NSString *notifyImageString = newNotifyingValue ? @"PropertyNotifyEnabled" : @"PropertyNotifyDisabled";
    [self.notifyButton setBackgroundImage:[UIImage imageNamed:notifyImageString] forState:UIControlStateNormal];
}

@end
