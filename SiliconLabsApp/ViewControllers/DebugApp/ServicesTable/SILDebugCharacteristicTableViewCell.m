//
//  SILDebugCharacteristicTableViewCell.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/7/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDebugCharacteristicTableViewCell.h"
#import "SILDebugCharacteristicPropertyView.h"
#import "SILCharacteristicTableModel.h"
#import "SILBluetoothCharacteristicModel.h"
#import "SILDescriptorTableModel.h"
#import "UIView+NibInitable.h"
#import "UIImage+SILImages.h"
#import "SILBluetoothBrowser+Constants.h"
#if ENABLE_HOMEKIT
#import "SILHomeKitCharacteristicTableModel.h"
#endif

@interface SILDebugCharacteristicTableViewCell()
@property (weak, nonatomic) IBOutlet UIView *topSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *propertiesContainerView;
@property (weak, nonatomic) IBOutlet UIStackView *propertyButtonsStackView;
@property (weak, nonatomic) IBOutlet UILabel *characteristicNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *characteristicUuidLabel;
@property (weak, nonatomic) IBOutlet UIImageView *viewMoreChevron;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *iPadBottomDividerLeadingConstraint;
@property (weak, nonatomic) IBOutlet UILabel *descriptorsTextLabel;
@property (weak, nonatomic) IBOutlet UIView *descriptorsView;
@property (weak, nonatomic) IBOutlet UIButton *readPropertyButton;
@property (weak, nonatomic) IBOutlet UIButton *writePropertyButton;
@property (weak, nonatomic) IBOutlet UIButton *writeNoResponsePropertyButton;
@property (weak, nonatomic) IBOutlet UIButton *notifyPropertyButton;
@property (weak, nonatomic) IBOutlet UIButton *indicatePropertyButton;

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray<UIButton *> * allPropertyViews;
@property (strong, nonatomic) NSArray *allActiveProperties;

@property (strong, nonatomic) CBCharacteristic *characteristic;

@end

@implementation SILDebugCharacteristicTableViewCell

NSString * const KVONotifyingName = @"notifying";

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self addGestureRecognizerForCharacteristicNameLabel];
}

- (void)configureWithCharacteristicModel:(SILCharacteristicTableModel *)characteristicModel {
    [self updateChevronImageForExpanded:characteristicModel.isExpanded];
    self.characteristicTableModel = characteristicModel;
    self.characteristic = characteristicModel.characteristic;
    [self.nameEditButton setHidden:!characteristicModel.isMappable];
    self.characteristicNameLabel.text = [characteristicModel name];
    self.characteristicUuidLabel.text = [characteristicModel hexUuidString] ?: EmptyText;
    if (characteristicModel.descriptorModels.count == 0) {
        [self.descriptorsView setHidden:YES];
    } else {
        [self.descriptorsView setHidden:NO];
        self.descriptorsTextLabel.text = [self getDescriptorsText:characteristicModel.descriptorModels];
    }
    self.topSeparatorView.hidden = characteristicModel.hideTopSeparator;
    [self configureAsExpandable:[characteristicModel canExpand] || [characteristicModel isUnknown]];
    self.allActiveProperties = [SILDebugProperty getActivePropertiesFrom:characteristicModel.characteristic.properties];
    [self configurePropertyViewsForProperties:self.allActiveProperties];
    [self togglePropertyEnabledIfExpanded];
    [self layoutIfNeeded];
}

- (NSString*)getDescriptorsText:(NSArray*)descriptorsModel {
    NSMutableString* text = [[NSMutableString alloc] initWithString:EmptyText];
    for (SILDescriptorTableModel* descriptor in descriptorsModel) {
        [text appendString:[[NSString alloc] initWithFormat:@"%@", descriptor.descriptor.UUID]];
        [text appendString:@" (UUID: "];
        [text appendString:[[NSString alloc] initWithFormat:@"%@", descriptor.hexUuidString]];
        [text appendString:@")\n"];
    }
    
    return [[NSString alloc] initWithString:text];
}

- (void)addGestureRecognizerForCharacteristicNameLabel {
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(characteristicNameLabelWasTapped)];
    [self.characteristicNameLabel setUserInteractionEnabled:YES];
    [self.characteristicNameLabel addGestureRecognizer:tap];
}

- (void)characteristicNameLabelWasTapped {
    if (![self.nameEditButton isHidden]) {
        [self.delegate editNameWithCell:self];
    }
}

#if ENABLE_HOMEKIT
- (void)configureWithHomeKitCharacteristicModel:(SILHomeKitCharacteristicTableModel *)homeKitCharacteristicModel {
    self.characteristicNameLabel.text = homeKitCharacteristicModel.name ?: UknownCharacteristicName;
    self.characteristicUuidLabel.text = [homeKitCharacteristicModel uuidString] ?: EmptyText;
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

    for (UIButton *view in self.allPropertyViews) {
        [view setHidden:YES];
    }
    
    for (SILDebugProperty *property in properties) {
        id propertyKey = property.keysForActivation.firstObject;
        if ([propertyKey isEqual:@(CBCharacteristicPropertyRead)]) {
            [self.readPropertyButton setHidden:NO];
        } else if ([propertyKey isEqual:@(CBCharacteristicPropertyWrite)]) {
            [self.writePropertyButton setHidden:NO];
        } else if ([propertyKey isEqual:@(CBCharacteristicPropertyWriteWithoutResponse)]) {
            [self.writeNoResponsePropertyButton setHidden:NO];
        } else if ([propertyKey isEqual:@(CBCharacteristicPropertyIndicate)]) {
            [self.indicatePropertyButton setHidden:NO];
        } else if ([propertyKey isEqual:@(CBCharacteristicPropertyNotify)]) {
            [self.notifyPropertyButton setHidden:NO];
        }
    }
}

#pragma mark - SILGenericAttributeTableCell

- (void)expandIfAllowed:(BOOL)isExpanding {
    [self togglePropertyEnabledIfExpanded];
    [self updateChevronImageForExpanded:isExpanding];
}

- (void)updateChevronImageForExpanded:(BOOL)expanded {
    self.viewMoreChevron.image = [UIImage imageNamed: expanded ? SILImageChevronExpanded : SILImageChevronCollapsed];
}

- (void)togglePropertyEnabledIfExpanded {
    BOOL expanded = self.characteristicTableModel.isExpanded;
    BOOL isNotifying = [[self.characteristic valueForKey:KVONotifyingName] boolValue];
        
    for (SILDebugProperty *property in self.allActiveProperties) {
        if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyRead)]) {
            [self.readPropertyButton setUserInteractionEnabled:expanded];
            [self readButtonAppearanceWithCondition:expanded];
        } else if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyWrite)]) {
            [self.writePropertyButton setUserInteractionEnabled:expanded];
            [self writeButtonAppearanceWithCondition:expanded];
        } else if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyWriteWithoutResponse)]) {
            [self.writeNoResponsePropertyButton setUserInteractionEnabled:expanded];
            [self writeNoResponseButtonAppearanceWithCondition:expanded];
        } else if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyIndicate)]) {
            [self.indicatePropertyButton setUserInteractionEnabled:expanded];
            [self indicateButtonAppearanceWithCondition:(expanded && isNotifying)];
        } else if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyNotify)]) {
            [self.notifyPropertyButton setUserInteractionEnabled:expanded];
            [self notifyButtonAppearanceWithCondition:(expanded && isNotifying)];
        }
    }
}

#pragma mark - Buttons Appearance
- (void)readButtonAppearanceWithCondition:(BOOL)condition {
    NSString *readImageString = condition ? SILImageNamePropertyRead : SILImageNamePropertyReadDisabled;
    self.readPropertyButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.readPropertyButton setImage:[UIImage imageNamed:readImageString] forState:UIControlStateNormal];
    if (condition) {
        [self.readPropertyButton setTitleColor:[UIColor sil_regularBlueColor] forState:UIControlStateNormal];
    } else {
        [self.readPropertyButton setTitleColor:[UIColor sil_primaryTextColor] forState:UIControlStateNormal];
    }
}

- (void)writeButtonAppearanceWithCondition:(BOOL)condition {
    NSString *writeImageString = condition ? SILImageNamePropertyWrite : SILImageNamePropertyWriteDisabled;
    self.writePropertyButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.writePropertyButton setImage:[UIImage imageNamed:writeImageString] forState:UIControlStateNormal];
    if (condition) {
        [self.writePropertyButton setTitleColor:[UIColor sil_regularBlueColor] forState:UIControlStateNormal];
    } else {
        [self.writePropertyButton setTitleColor:[UIColor sil_primaryTextColor] forState:UIControlStateNormal];
    }
}

- (void)writeNoResponseButtonAppearanceWithCondition:(BOOL)condition {
    NSString *writeImageString = condition ? SILImageNamePropertyWriteNoResponse : SILImageNamePropertyWriteNoResponseDisabled;
    self.writeNoResponsePropertyButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.writeNoResponsePropertyButton setImage:[UIImage imageNamed:writeImageString] forState:UIControlStateNormal];
    if (condition) {
        [self.writeNoResponsePropertyButton setTitleColor:[UIColor sil_regularBlueColor] forState:UIControlStateNormal];
    } else {
        [self.writeNoResponsePropertyButton setTitleColor:[UIColor sil_primaryTextColor] forState:UIControlStateNormal];
    }
}

- (void)indicateButtonAppearanceWithCondition:(BOOL)condition {
    NSString *indicateImageString = condition ? SILImageNamePropertyIndicate : SILImageNamePropertyIndicateDisabled;
    self.indicatePropertyButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.indicatePropertyButton setImage:[UIImage imageNamed:indicateImageString] forState:UIControlStateNormal];
    if (condition) {
        [self.indicatePropertyButton setTitleColor:[UIColor sil_regularBlueColor] forState:UIControlStateNormal];
    } else {
        [self.indicatePropertyButton setTitleColor:[UIColor sil_primaryTextColor] forState:UIControlStateNormal];
    }
}

- (void)notifyButtonAppearanceWithCondition:(BOOL)condition {
    NSString *notifyImageString = condition ? SILImageNamePropertyNotify : SILImageNamePropertyNotifyDisabled;
    self.notifyPropertyButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.notifyPropertyButton setImage:[UIImage imageNamed:notifyImageString] forState:UIControlStateNormal];
    if (condition) {
        [self.notifyPropertyButton setTitleColor:[UIColor sil_regularBlueColor] forState:UIControlStateNormal];
    } else {
        [self.notifyPropertyButton setTitleColor:[UIColor sil_primaryTextColor] forState:UIControlStateNormal];
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
    BOOL newNotifyingValue = ![[self.characteristic valueForKey:KVONotifyingName] boolValue];
    [self.delegate cell:self didRequestIndicateForCharacteristic:self.characteristic withValue:newNotifyingValue];
    [self indicateButtonAppearanceWithCondition:newNotifyingValue];
}

- (IBAction)handleNotifyViewTap:(id)sender {
    BOOL newNotifyingValue = ![[self.characteristic valueForKey:KVONotifyingName] boolValue];
    [self.delegate cell:self didRequestNotifyForCharacteristic:self.characteristic withValue:newNotifyingValue];
    [self notifyButtonAppearanceWithCondition:newNotifyingValue];
}

- (IBAction)editName:(UIButton *)sender {
    if (_delegate != nil) {
        [_delegate editNameWithCell:self];
    }
}

@end
