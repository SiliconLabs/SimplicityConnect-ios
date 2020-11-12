//
//  SILTextFieldEntryCell.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/3/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILTextFieldEntryCell.h"
#import "SILKeyValueViewModel.h"

@implementation SILTextFieldEntryCell

#pragma mark - Cell Lifecycle

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.valueTextField.borderStyle = UITextBorderStyleNone;
    self.allowsTextEntry = YES;
    [self configureForTextEntry];
}

#pragma mark - Properties

- (void)setAllowsTextEntry:(BOOL)allowsTextEntry {
    _allowsTextEntry = allowsTextEntry;
    [self configureForTextEntry];
}

- (void)setCallToAction:(NSString *)callToAction {
    _callToAction = callToAction;
    [self configureForTextEntry];
}

#pragma mark - Public

- (void)configureWithKeyValueViewModel:(SILKeyValueViewModel *)keyValueViewModel {
    self.typeLabel.text = keyValueViewModel.keyString;
    self.valueTextField.text = keyValueViewModel.valueString;
    self.valueLabel.text = keyValueViewModel.valueString;
    [self configureForTextEntry];
}

#pragma mark - Helpers

- (void)configureForTextEntry {
    BOOL hasFileName = _valueLabel.text.length > 0;
    self.valueTextField.hidden = !_allowsTextEntry;
    self.valueLabel.hidden = _allowsTextEntry && !hasFileName;
    self.chooseFileLabel.text = _callToAction;
    self.chooseFileLabel.hidden = hasFileName || _callToAction.length == 0;
    self.clearTextHitView.hidden = !hasFileName;
    self.valueTextFieldUnderlineView.hidden = self.valueTextField.hidden;
}

@end
