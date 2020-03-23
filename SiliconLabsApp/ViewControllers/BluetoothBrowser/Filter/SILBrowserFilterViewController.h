//
//  SILBrowserFilterViewController.h
//  BlueGecko
//
//  Created by Kamil Czajka on 14/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILBrowserFilterViewControllerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface SILBrowserFilterViewController : UIViewController

@property (retain, nonatomic) id <SILBrowserFilterViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
