//
//  SILDebugCharacteristicEncodingViewController.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/3/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILDebugPopoverViewController.h"
#import "SILCharacteristicEditEnabler.h"

@class SILCharacteristicTableModel;

@interface SILDebugCharacteristicEncodingViewController : SILDebugPopoverViewController  <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (strong, nonatomic) id<SILCharacteristicEditEnablerDelegate> editDelegate;
- (instancetype)initWithCharacteristicTableModel:(SILCharacteristicTableModel *)characteristicModel canEdit:(BOOL)canEdit;
@end
