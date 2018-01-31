//
//  SILTextFieldEntryCell.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/3/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SILKeyValueViewModel;

@interface SILTextFieldEntryCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UILabel *chooseFileLabel;
@property (weak, nonatomic) IBOutlet UITextField *valueTextField;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UIView *clearTextHitView;
@property (weak, nonatomic) IBOutlet UIView *valueTextFieldUnderlineView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomMarginConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topMarginConstraint;
@property (weak, nonatomic) IBOutlet UIView *splitterView;

/**
 If allowsTextEntry is set to YES, valueLabel will be hidden. If allowsTextEntry is set to NO, valueTextField will be hidden.
 */
@property (nonatomic) BOOL allowsTextEntry;
@property (nonatomic) NSString *callToAction;

- (void)configureWithKeyValueViewModel:(SILKeyValueViewModel *)keyValueViewModel;

@end
