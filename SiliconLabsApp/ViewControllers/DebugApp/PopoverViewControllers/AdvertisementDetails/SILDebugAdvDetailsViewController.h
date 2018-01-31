//
//  SILDebugAdvDetailsViewController.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/14/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILDebugPopoverViewController.h"

@class SILDiscoveredPeripheralDisplayDataViewModel;

@interface SILDebugAdvDetailsViewController : SILDebugPopoverViewController  <UITableViewDataSource, UITableViewDelegate>
- (instancetype)initWithPeripheralViewModel:(SILDiscoveredPeripheralDisplayDataViewModel *)peripheralViewModel;
@end
