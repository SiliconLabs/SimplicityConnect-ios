//
//  SILBrowserLogViewController.h
//  BlueGecko
//
//  Created by Kamil Czajka on 14/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILBrowserLogViewControllerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface SILBrowserLogViewController : UIViewController

@property (retain, nonatomic) id <SILBrowserLogViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
