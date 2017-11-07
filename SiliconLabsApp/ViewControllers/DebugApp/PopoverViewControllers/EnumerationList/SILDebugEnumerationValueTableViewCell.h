//
//  SILDebugEnumerationValueTableViewCell.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/3/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SILDebugEnumerationValueTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UIImageView *activeCheckImageView;
@end
