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
        return CGSizeMake(300, 200);
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
    NSError * saveError = nil;
    NSString * const backupValue = self.valueModel.primaryValue;
    
    self.valueModel.primaryValue = self.valueTextField.text;
    [self.editDelegate saveCharacteristic:self.valueModel.parentCharacteristicModel error:&saveError];
    
    if (saveError != nil) {
        self.valueModel.primaryValue = backupValue;
        self.invalidInputLabel.text = saveError.localizedDescription;
        self.invalidInputLabel.hidden = NO;
    } else {
        [self.popoverDelegate didClosePopoverViewController:self];
    }
}

@end
