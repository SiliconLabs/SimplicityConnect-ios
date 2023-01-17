//
//  SILBrowserConnectionsViewController.h
//  BlueGecko
//
//  Created by Kamil Czajka on 14/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILBrowserConnectionsViewControllerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface SILBrowserConnectionsViewController : UIViewController

@property (retain, nonatomic) id <SILBrowserConnectionsViewControllerDelegate> delegate;
- (void)disconnectAllTapped;
@end

NS_ASSUME_NONNULL_END
