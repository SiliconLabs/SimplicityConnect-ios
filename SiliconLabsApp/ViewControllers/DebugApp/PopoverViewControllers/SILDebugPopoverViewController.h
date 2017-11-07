//
//  SILDebugPopoverViewController.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/3/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SILDebugPopoverViewController, SILCharacteristicTableModel;

@protocol SILDebugPopoverViewControllerDelegate;

@interface SILDebugPopoverViewController : UIViewController
@property (weak, nonatomic) id<SILDebugPopoverViewControllerDelegate> popoverDelegate;
@property (weak, nonatomic) IBOutlet UILabel *generalTitle;
@property (weak, nonatomic) IBOutlet UILabel *specificTitle;
@property (weak, nonatomic) IBOutlet UITableView *popoverTable;
@end

@protocol SILDebugPopoverViewControllerDelegate <NSObject>
- (void)didClosePopoverViewController:(SILDebugPopoverViewController *)popoverViewController;
@end
