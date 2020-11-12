//
//  SILDebugCharacteristicEncodingFieldEntryCell.m
//  SiliconLabsApp
//
//  Created by Grzegorz Janosz on 29/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILDebugCharacteristicEncodingFieldEntryCell.h"

@interface SILDebugCharacteristicEncodingFieldEntryCell() <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIButton *pasteButton;

@end

@implementation SILDebugCharacteristicEncodingFieldEntryCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.pasteButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.pasteButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    self.pasteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    self.valueTextField.delegate = self;
    self.index = -1;
}

- (IBAction)pasteButtonClicked:(UIButton *)sender {
    [self.delegate pasteButtonWasClickedWithTextField:self.valueTextField atIndex:self.index];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [self setupKeyboard];
    return true;
}

- (void)setupKeyboard {
    if (self.index == 0) {
        self.valueTextField.keyboardType = UIKeyboardTypeDefault;
    } else if (self.index == 2) {
        self.valueTextField.keyboardType = UIKeyboardTypeNumberPad;
        [self.valueTextField addDoneButton];
    } else {
        self.valueTextField.keyboardType = UIKeyboardTypeASCIICapable;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString * const latestString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self.delegate changeText:latestString inTextField:self.valueTextField atIndex:self.index];
    
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

@end
