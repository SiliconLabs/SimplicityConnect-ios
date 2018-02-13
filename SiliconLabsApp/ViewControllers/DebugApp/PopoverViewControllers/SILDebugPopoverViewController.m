//
//  SILDebugPopoverViewController.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/3/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDebugPopoverViewController.h"

@implementation SILDebugPopoverViewController

#pragma mark - Lifecycle

- (CGSize)preferredContentSize {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return CGSizeMake(500, 770);
    } else {
        return CGSizeMake(300, 500);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupTable];
}

#pragma mark - Setup

- (void)setupTable {
    self.popoverTable.rowHeight = UITableViewAutomaticDimension;
    self.popoverTable.estimatedRowHeight = 100;
}

@end
