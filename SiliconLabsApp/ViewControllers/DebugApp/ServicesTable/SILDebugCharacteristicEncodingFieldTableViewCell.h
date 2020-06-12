//
//  SILDebugCharacteristicEncodingFieldTableViewCell.h
//  SiliconLabsApp
//
//  Created by Glenn Martin on 11/10/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SILDebugCharacteristicEncodingFieldTableViewCell : UITableViewCell
@property(weak, nonatomic) IBOutlet UILabel *hexValueLabel;
@property(weak, nonatomic) IBOutlet UILabel *asciiValueLabel;
@property(weak, nonatomic) IBOutlet UILabel *decimalValueLabel;
@property(weak, nonatomic) IBOutlet UILabel* editLabel;
- (void)clearValues;
@end
