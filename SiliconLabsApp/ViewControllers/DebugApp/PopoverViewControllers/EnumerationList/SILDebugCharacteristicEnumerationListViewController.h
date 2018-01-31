//
//  SILDebugCharacterostocEnumerationListTableViewControllSILDebugCharacteristicEnumerationListViewController.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/3/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILDebugPopoverViewController.h"
#import "SILCharacteristicEditEnabler.h"

@class SILEnumerationFieldRowModel, SILCharacteristicTableModel;

@interface SILDebugCharacteristicEnumerationListViewController : SILDebugPopoverViewController  <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) id<SILCharacteristicEditEnablerDelegate> editDelegate;
- (instancetype)initWithEnumeration:(SILEnumerationFieldRowModel *)enumerationViewModel canEdit:(BOOL)canEdit;
@end
