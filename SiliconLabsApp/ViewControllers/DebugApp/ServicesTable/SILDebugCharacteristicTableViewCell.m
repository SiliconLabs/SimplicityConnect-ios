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

@interface SILDebugCharacteristicTableViewCell() <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UIView *topSeparatorView;
@property (weak, nonatomic) IBOutlet UILabel *characteristicNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *characteristicUuidLabel;
@property (weak, nonatomic) IBOutlet UIView *descriptorsView;
@property (weak, nonatomic) IBOutlet UIButton *readPropertyButton;
@property (weak, nonatomic) IBOutlet UIButton *writePropertyButton;
@property (weak, nonatomic) IBOutlet UIButton *notifyPropertyButton;
@property (weak, nonatomic) IBOutlet UIButton *indicatePropertyButton;
@property (weak, nonatomic) IBOutlet UITableView *descriptorsTable;

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray<UIButton *> * allPropertyViews;
@property (strong, nonatomic) NSArray *allActiveProperties;
@property (strong, nonatomic) NSArray* descriptorModels;

@property (strong, nonatomic) CBCharacteristic *characteristic;

@end

@implementation SILDebugCharacteristicTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self addGestureRecognizerForCharacteristicNameLabel];
    [self setupDescriptorTable];
}

- (void)setupDescriptorTable {
    self.descriptorModels = @[];
    self.descriptorsTable.dataSource = self;
    self.descriptorsTable.delegate = self;
    [self.descriptorsTable invalidateIntrinsicContentSize];
}

- (void)configureWithCharacteristicModel:(SILCharacteristicTableModel *)characteristicModel {
    self.characteristicTableModel = characteristicModel;
    self.characteristic = characteristicModel.characteristic;
    [self.nameEditButton setHidden:!characteristicModel.isMappable];
    self.characteristicNameLabel.text = [characteristicModel name];
    self.characteristicUuidLabel.text = [characteristicModel hexUuidString] ?: EmptyText;
    self.descriptorModels = characteristicModel.descriptorModels;
    if (self.descriptorModels.count == 0) {
        [self.descriptorsView setHidden:YES];
    } else {
        [self.descriptorsView setHidden:NO];
    }
    
    [self.descriptorsTable reloadData];

    self.topSeparatorView.hidden = characteristicModel.hideTopSeparator;
    self.allActiveProperties = [SILDebugProperty getActivePropertiesFrom:characteristicModel.characteristic.properties];
    [self configurePropertyViewsForProperties:self.allActiveProperties];
    [self toggleProperties];
    [self layoutIfNeeded];
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
    [self configureAsExpandable:NO];
}
#endif

- (void)configurePropertyViewsForProperties:(NSArray *)properties {
    [self layoutIfNeeded];

    for (UIButton *view in self.allPropertyViews) {
        [view setHidden:YES];
    }
    
    for (SILDebugProperty *property in properties) {
        id propertyKey = property.keysForActivation.firstObject;
        if ([propertyKey isEqual:@(CBCharacteristicPropertyRead)]) {
            [self.readPropertyButton setHidden:NO];
        } else if ([propertyKey isEqual:@(CBCharacteristicPropertyWrite)] ||
                   [propertyKey isEqual:@(CBCharacteristicPropertyWriteWithoutResponse)]) {
            [self.writePropertyButton setHidden:NO];
        } else if ([propertyKey isEqual:@(CBCharacteristicPropertyIndicate)]) {
            [self.indicatePropertyButton setHidden:NO];
        } else if ([propertyKey isEqual:@(CBCharacteristicPropertyNotify)]) {
            [self.notifyPropertyButton setHidden:NO];
        }
    }
}

#pragma mark - SILGenericAttributeTableCell

- (void)expandIfAllowed:(BOOL)isExpanding {
    [self toggleProperties];
}

- (void)toggleProperties {
    BOOL isNotifying = [self.characteristic isNotifying];
        
    for (SILDebugProperty *property in self.allActiveProperties) {
        if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyRead)]) {
            [self readButtonAppearance];
        } else if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyWrite)] ||
                   [property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyWriteWithoutResponse)]) {
            [self writeButtonAppearance];
        } else if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyIndicate)]) {
            [self indicateButtonAppearanceWithCondition:isNotifying];
        } else if ([property.keysForActivation.firstObject isEqual:@(CBCharacteristicPropertyNotify)]) {
            [self notifyButtonAppearanceWithCondition:isNotifying];
        }
    }
}

#pragma mark - Buttons Appearance

- (void)readButtonAppearance {
    NSString *readImageString = SILImageNamePropertyReadDisabled;
    self.readPropertyButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.readPropertyButton setImage:[UIImage imageNamed:readImageString] forState:UIControlStateNormal];
    [self.readPropertyButton setTitleColor:[UIColor sil_boulderColor] forState:UIControlStateNormal];
}

- (void)writeButtonAppearance {
    NSString *writeImageString = SILImageNamePropertyWriteDisabled;
    self.writePropertyButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.writePropertyButton setImage:[UIImage imageNamed:writeImageString] forState:UIControlStateNormal];
    [self.writePropertyButton setTitleColor:[UIColor sil_boulderColor] forState:UIControlStateNormal];
}


- (void)indicateButtonAppearanceWithCondition:(BOOL)condition {
    NSString *indicateImageString = condition ? SILImageNamePropertyIndicate : SILImageNamePropertyIndicateDisabled;
    self.indicatePropertyButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.indicatePropertyButton setImage:[UIImage imageNamed:indicateImageString] forState:UIControlStateNormal];
    if (condition) {
        [self.indicatePropertyButton setTitleColor:[UIColor sil_regularBlueColor] forState:UIControlStateNormal];
    } else {
        [self.indicatePropertyButton setTitleColor:[UIColor sil_boulderColor] forState:UIControlStateNormal];
    }
}

- (void)notifyButtonAppearanceWithCondition:(BOOL)condition {
    NSString *notifyImageString = condition ? SILImageNamePropertyNotify : SILImageNamePropertyNotifyDisabled;
    self.notifyPropertyButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.notifyPropertyButton setImage:[UIImage imageNamed:notifyImageString] forState:UIControlStateNormal];
    if (condition) {
        [self.notifyPropertyButton setTitleColor:[UIColor sil_regularBlueColor] forState:UIControlStateNormal];
    } else {
        [self.notifyPropertyButton setTitleColor:[UIColor sil_boulderColor] forState:UIControlStateNormal];
    }
}

#pragma mark - Button Actions

- (IBAction)handleReadViewTap:(id)sender {
    [self.characteristicTableModel expandFieldIfNeeded];
    [self.delegate cell:self didRequestReadForCharacteristic:self.characteristic];
}

- (IBAction)handleWriteViewTap:(id)sender {
    [self.characteristicTableModel expandFieldIfNeeded];
    [self.delegate cell:self didRequestWriteForCharacteristic:self.characteristic];
}

- (IBAction)handleIndicateViewTap:(id)sender {
    BOOL newNotifyingValue = ![self.characteristic isNotifying];
    [self indicateButtonAppearanceWithCondition:newNotifyingValue];
    if (newNotifyingValue) {
        [self.characteristicTableModel expandFieldIfNeeded];
    }
    [self.delegate cell:self didRequestIndicateForCharacteristic:self.characteristic withValue:newNotifyingValue];
}

- (IBAction)handleNotifyViewTap:(id)sender {
    BOOL newNotifyingValue = ![self.characteristic isNotifying];
    [self notifyButtonAppearanceWithCondition:newNotifyingValue];
    if (newNotifyingValue) {
        [self.characteristicTableModel expandFieldIfNeeded];
    }
    [self.delegate cell:self didRequestNotifyForCharacteristic:self.characteristic withValue:newNotifyingValue];
}

- (IBAction)editName:(UIButton *)sender {
    if (_delegate != nil) {
        [_delegate editNameWithCell:self];
    }
}

// MARK: UITableViewDataSource

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.descriptorModels.count;
}

- (UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    SILDescriptorTableViewCell* descriptorCell = [tableView dequeueReusableCellWithIdentifier:@"SILDescriptorTableViewCell" forIndexPath:indexPath];
    SILDescriptorTableModel* descriptor = self.descriptorModels[indexPath.row];
    [descriptorCell configureCellWithDescriptor:descriptor];
    descriptorCell.delegate = self.descriptorDelegate;
    return descriptorCell;
}

@end
