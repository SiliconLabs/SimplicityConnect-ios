//
//  SILDebugCharacteristicEncodingFieldTableViewCell.h
//  SiliconLabsApp
//
//  Created by Glenn Martin on 11/10/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILDebugCharacteristicEncodingFieldView.h"

@class SILDebugCharacteristicEncodingFieldTableViewCell;
@protocol SILDebugCharacteristicEncodingFieldTableViewCellDelegate <NSObject>

@required
- (void)copyButtonWasClicked;

@end

@interface SILDebugCharacteristicEncodingFieldTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet SILDebugCharacteristicEncodingFieldView *hexView;
@property (weak, nonatomic) IBOutlet SILDebugCharacteristicEncodingFieldView *asciiView;
@property (weak, nonatomic) IBOutlet SILDebugCharacteristicEncodingFieldView *decimalView;

@property(weak, nonatomic) id <SILDebugCharacteristicEncodingFieldTableViewCellDelegate> delegate;
- (void)clearValues;
@end

