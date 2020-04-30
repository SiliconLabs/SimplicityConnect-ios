//
//  SILValueFieldEditorViewController.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/9/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILValueFieldEditorViewController.h"
#import "SILValueFieldRowModel.h"
#import "SILCharacteristicTableModel.h"
#import "SILBluetoothCharacteristicModel.h"
#import "SILBluetoothBrowser+Constants.h"

@interface SILValueFieldEditorViewController ()
@property (strong, nonatomic) SILValueFieldRowModel *valueModel;
@property (weak, nonatomic) IBOutlet UITextField *valueTextField;
@property (weak, nonatomic) IBOutlet UILabel *invalidInputLabel;
@end

@implementation SILValueFieldEditorViewController

#pragma mark - Lifecycle

- (instancetype)initWithValueFieldModel:(SILValueFieldRowModel *)valueModel {
    self = [super self];
    if (self) {
        self.valueModel = valueModel;
    }
    return self;
}

- (void)viewDidLoad {
    self.generalTitle.text = self.valueModel.parentCharacteristicModel.bluetoothModel.name;
    self.specificTitle.text = self.valueModel.fieldModel.name;
    self.valueTextField.borderStyle = UITextBorderStyleNone;
    self.invalidInputLabel.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [self.valueTextField becomeFirstResponder];
}

- (CGSize)preferredContentSize {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return CGSizeMake(500, 300);
    } else {
        return CGSizeMake(300, 220);
    }
}

#pragma mark - IBActions

- (IBAction)inputValueChanged:(UITextField *)sender {
    self.invalidInputLabel.hidden = YES;
}

- (IBAction)didTapCancel:(UIButton *)sender {
    [self.popoverDelegate didClosePopoverViewController:self];
}

- (IBAction)didTapSave:(UIButton *)sender {
    if (self.valueTextField.text.length == 0) {
        [self dislayErrorMessage:CannotWriteEmptyTextToCharacteristic];
    } else {
        NSString * const backupValue = self.valueModel.primaryValue;
        NSError * const saveError = [self tryToSaveValueInCharacteristic];
        if (saveError != nil) {
            self.valueModel.primaryValue = backupValue;
            [self dislayErrorMessage:saveError.localizedDescription];
        } else {
            [self.popoverDelegate didClosePopoverViewController:self];
        }
    }
}

- (void)dislayErrorMessage:(NSString*)message {
    self.invalidInputLabel.text = message;
    self.invalidInputLabel.hidden = NO;
}

- (NSError*)tryToSaveValueInCharacteristic {
    NSError * saveError = nil;
    self.valueModel.primaryValue = self.valueTextField.text;
    [self.editDelegate saveCharacteristic:self.valueModel.parentCharacteristicModel error:&saveError];
    
    return saveError;
}

@end
