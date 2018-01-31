//
//  SILDebugCharacteristicEnumerationTableViewCell.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/28/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SILEnumerationFieldRowModel;

@interface SILDebugCharacteristicEnumerationFieldTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *writeChevronImageView;
- (void)configureWithEnumerationModel:(SILEnumerationFieldRowModel *)enumerationModel;
@end
