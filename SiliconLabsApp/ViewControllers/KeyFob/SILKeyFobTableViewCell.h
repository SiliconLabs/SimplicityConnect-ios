//
//  SILKeyFobTableViewCell.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/2/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol SILKeyFobTableViewCellDelegate;

@interface SILKeyFobTableViewCell : UITableViewCell

@property (weak, nonatomic) id<SILKeyFobTableViewCellDelegate> delegate;
@property (strong, nonatomic) id context;

@property (weak, nonatomic) IBOutlet UIImageView *strengthImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *strengthLabel;

@end

@protocol SILKeyFobTableViewCellDelegate <NSObject>

- (void)didSelectFindMeWithKeyFobTableViewCell:(SILKeyFobTableViewCell *)cell;

@end