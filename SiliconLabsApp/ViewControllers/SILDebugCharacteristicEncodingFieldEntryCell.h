//
//  SILDebugCharacteristicEncodingFieldEntryCell.h
//  SiliconLabsApp
//
//  Created by Grzegorz Janosz on 29/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILEncodingTextField.h"

NS_ASSUME_NONNULL_BEGIN

@class SILDebugCharacteristicEncodingFieldEntryCell;
@protocol SILDebugCharacteristicEncodingFieldEntryCellDelegate <NSObject>

@required
- (void)pasteButtonWasClickedWithTextField:(SILEncodingTextField *)textField atIndex:(NSInteger)index;
@required
- (void)changeText:(NSString*)text inTextField:(SILEncodingTextField *)textField atIndex:(NSInteger)index;

@end

@interface SILDebugCharacteristicEncodingFieldEntryCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet SILEncodingTextField *valueTextField;
@property NSInteger index;
@property(weak, nonatomic) id <SILDebugCharacteristicEncodingFieldEntryCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
