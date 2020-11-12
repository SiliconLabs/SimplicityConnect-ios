//
//  SILBrowserSettings.h
//  BlueGecko
//
//  Created by Grzegorz Janosz on 18/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SILBrowserSettings : NSObject

+ (BOOL)displayExitWarningPopup;
+ (void)setDisplayExitWarningPopup:(BOOL)displayExitWarningPopup;

@end

NS_ASSUME_NONNULL_END
