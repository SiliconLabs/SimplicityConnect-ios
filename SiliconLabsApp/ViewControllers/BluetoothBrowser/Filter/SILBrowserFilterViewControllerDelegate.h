//
//  SILBrowserFilterViewControllerDelegate.h
//  BlueGecko
//
//  Created by Kamil Czajka on 14/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILBrowserFilterViewModel.h"

@class SILBrowserFilterViewController;
@protocol SILBrowserFilterViewControllerDelegate <NSObject>
- (void)backButtonWasTapped;
- (void)applyFiltersButtonWasTapped:(SILBrowserFilterViewModel*)viewModel;
@end
