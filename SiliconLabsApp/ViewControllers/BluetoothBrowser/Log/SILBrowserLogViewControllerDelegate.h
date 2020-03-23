//
//  SILBrowserLogViewControllerDelegate.h
//  BlueGecko
//
//  Created by Kamil Czajka on 14/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SILBrowserLogViewController;
@protocol SILBrowserLogViewControllerDelegate <NSObject>
- (void)logViewBackButtonPressed;
@end
