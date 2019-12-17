//
//  SILDebugCharacteristicEncodingViewController.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/3/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "SILDebugCharacteristicEncodingViewController.h"
#import "SILCharacteristicTableModel.h"
#import "SILTextFieldEntryCell.h"
#import "SILCharacteristicFieldValueResolver.h"
#import "SILDebugProperty.h"
#import "SILDebugCharacteristicPropertyView.h"
#import "UITableViewCell+SILHelpers.h"
#import "UIView+NibInitable.h"

NSString * const kHex = @"HEX";
NSString * const kAscii = @"ASCII";
NSString * const kDecimal = @"DECIMAL";

@interface SILDebugCharacteristicEncodingViewController ()
@property (strong, nonatomic) SILCharacteristicTableModel *characteristicModel;
@property (strong, nonatomic) NSArray *encodingTypes;
@property (strong, nonatomic) NSData *encodingData;
@property (strong, nonatomic) SILTextFieldEntryCell *sizingEncodingCell;

//TODO: refactor as a custom textfield class that resolve their own value
@property (strong, nonatomic) UITextField *hexField;
@property (strong, nonatomic) UITextField *asciiField;
@property (strong, nonatomic) UITextField *decimalField;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UILabel *serviceNameTitle;
@property (weak, nonatomic) IBOutlet UIView *propertiesContainerView;
@property (weak, nonatomic) IBOutlet UILabel *invalidInputLabel;

@property (nonatomic) BOOL canEdit;
@end

@implementation SILDebugCharacteristicEncodingViewController

#pragma mark - Lifecycle

- (instancetype)initWithCharacteristicTableModel:(SILCharacteristicTableModel *)characteristicModel canEdit:(BOOL)canEdit{
    self = [super init];
    if (self) {
        self.characteristicModel = characteristicModel;
        self.encodingTypes = @[kHex, kAscii, kDecimal];
        self.canEdit = canEdit;
        self.encodingData = self.characteristicModel.characteristic.value;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerNibs];
    [self setUpText];
    [self setupForIdiom];
    self.invalidInputLabel.hidden = YES;
}

- (CGSize)preferredContentSize {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return CGSizeMake(540, 495);
    } else {
        return CGSizeMake(296, 312);
    }
}

#pragma mark - Setup

- (void)registerNibs {
    NSString *cellClassString = NSStringFromClass([SILTextFieldEntryCell class]);
    [self.popoverTable registerNib:[UINib nibWithNibName:cellClassString bundle:nil] forCellReuseIdentifier:cellClassString];
    self.sizingEncodingCell = (SILTextFieldEntryCell *)[self.view initWithNibNamed:cellClassString];
}

- (void)setUpText {
    self.specificTitle.text = [self.characteristicModel uuidString];
    self.generalTitle.text = @"Unknown Characteristic";
    self.serviceNameTitle.text = @"Unknown Service";
    self.saveButton.enabled = self.canEdit;
}

- (void)setupForIdiom {
    BOOL isPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    
    self.propertiesContainerView.hidden = !isPad;
    
    if (!self.propertiesContainerView.hidden) {
        [SILDebugCharacteristicPropertyView addProperties:[SILDebugProperty getActivePropertiesFrom:self.characteristicModel.characteristic.properties] toContainerView:self.propertiesContainerView];
    }
    
    [self.view updateConstraints];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.encodingTypes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SILTextFieldEntryCell *encodingCell = [self.popoverTable dequeueReusableCellWithIdentifier:NSStringFromClass([SILTextFieldEntryCell class]) forIndexPath:indexPath];
    [self configureCell:encodingCell atIndexPath:indexPath];
    return encodingCell;
}

//Necessary for iOS7
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView.frame.size.height / self.encodingTypes.count - 8;
}

#pragma mark - Configure cell

- (void)configureCell:(SILTextFieldEntryCell *)encodingCell atIndexPath:(NSIndexPath *)indexPath {
    encodingCell.valueTextField.delegate = self;
    NSString *type = self.encodingTypes[indexPath.row];
    encodingCell.typeLabel.text = type;
    encodingCell.allowsTextEntry = YES;
    encodingCell.bottomMarginConstraint.constant = 16;
    encodingCell.topMarginConstraint.constant = 10;
    encodingCell.splitterView.hidden = YES;
    encodingCell.typeLabel.textColor = [UIColor.blackColor colorWithAlphaComponent:0.34];
    NSString *encodedValue;
    if ([type isEqual:kHex]) {
        if (![encodingCell isEqual:self.sizingEncodingCell]) {
            self.hexField = encodingCell.valueTextField;
        }
        encodedValue = [[SILCharacteristicFieldValueResolver sharedResolver] hexStringForData:self.encodingData decimalExponent:0];
    } else if ([type isEqual:kAscii]) {
        if (![encodingCell isEqual:self.sizingEncodingCell]) {
            self.asciiField = encodingCell.valueTextField;
        }
        encodedValue = [[SILCharacteristicFieldValueResolver sharedResolver] asciiStringForData:self.encodingData];
        encodedValue = [encodedValue stringByReplacingOccurrencesOfString:@"\0" withString:@""];
    } else {
        if (![encodingCell isEqual:self.sizingEncodingCell]) {
            self.decimalField = encodingCell.valueTextField;
        }
        encodedValue = [[SILCharacteristicFieldValueResolver sharedResolver] decimalStringForData:self.encodingData];
    }
    encodingCell.valueTextField.text = encodedValue;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSLog(@"Replacement String: %@ for rangeloc:%lu for rangelen:%lu", string, (unsigned long)range.location, (unsigned long)range.length);
    
    const BOOL isSpecialCharacter = [string isEqualToString:@"\b"] || [string isEqualToString:@""];
    const BOOL isHexField = [textField isEqual:self.hexField];
    const BOOL isDecimalField = [textField isEqual:self.decimalField];
    const BOOL isOtherField = !isHexField && ! isDecimalField;
    const BOOL shouldChangeHexField = isHexField && [self shouldChangeHexCharactersInRange:range replacementString:string];
    const BOOL shouldChangeDecimalField = isDecimalField && [self shouldChangeDecimalCharactersInRange:range replacementString:string];
    const BOOL shouldRefreshUI = isSpecialCharacter || isOtherField || (isHexField && shouldChangeHexField) || (isDecimalField && shouldChangeDecimalField);
    
    if (!shouldRefreshUI) {
        return NO;
    }
    
    NSError * dataError = nil;
    NSString * const latestString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    SILCharacteristicFieldValueResolver * const resolver = [SILCharacteristicFieldValueResolver sharedResolver];
    
    if ([textField isEqual:self.hexField]) {
        self.encodingData = [resolver dataForHexString:latestString decimalExponent:0 error:&dataError];
        if (self.encodingData) {
            self.asciiField.text = [resolver asciiStringForData:self.encodingData];
            self.decimalField.text = [resolver decimalStringForData:self.encodingData];
        }
    } else if ([textField isEqual:self.asciiField]){
        self.encodingData = [resolver dataForAsciiString:latestString];
        if (self.encodingData) {
            self.hexField.text = [resolver hexStringForData:self.encodingData decimalExponent:0];
            self.decimalField.text = [resolver decimalStringForData:self.encodingData];
        }
    } else if ([textField isEqual:self.decimalField]){
        self.encodingData = [resolver dataForDecimalString:latestString];
        if (self.encodingData) {
            self.hexField.text = [resolver hexStringForData:self.encodingData decimalExponent:0];
            self.asciiField.text = [resolver asciiStringForData:self.encodingData];
        }
    }
    
    if ([latestString isEqualToString:@""]) {
        self.hexField.text = latestString;
        self.asciiField.text = latestString;
        self.decimalField.text = latestString;
    }
    
    self.invalidInputLabel.hidden = YES;
    
    return self.canEdit;
}

#pragma mark - IBActions

- (IBAction)didTapCancel:(UIButton *)sender {
    [self.popoverDelegate didClosePopoverViewController:self];
}

- (IBAction)didTapSave:(UIButton *)sender {
    NSError * error = nil;
    NSData * const backupValue = [self.characteristicModel dataToWriteWithError:&error];
    
    self.encodingData = [[SILCharacteristicFieldValueResolver sharedResolver] dataForHexString:self.hexField.text decimalExponent:0 error:&error];
    [self.characteristicModel setIfAllowedFullWriteValue:self.encodingData];
    [self.editDelegate saveCharacteristic:self.characteristicModel error:&error];
    
    if (error != nil) {
        [self.characteristicModel setIfAllowedFullWriteValue:backupValue];
        self.invalidInputLabel.text = error.localizedDescription;
        self.invalidInputLabel.hidden = NO;
    } else {
        [self.popoverDelegate didClosePopoverViewController:self];
    }
}

#pragma mark - Text Field Value

- (BOOL)shouldChangeHexCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return ([string isEqualToString:@":"]) || [[SILCharacteristicFieldValueResolver sharedResolver] isLegalHexString:string length:string.length];
}

- (BOOL)shouldChangeDecimalCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return ([string isEqualToString:@" "]) || [[SILCharacteristicFieldValueResolver sharedResolver] isLegalDecimalString:string];
}

@end
