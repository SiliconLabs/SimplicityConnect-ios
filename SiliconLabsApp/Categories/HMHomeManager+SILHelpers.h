//
//  HMHomeManager+SILHelpers.h
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/12/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#if ENABLE_HOMEKIT
#import <HomeKit/HomeKit.h>
#endif

@interface HMHomeManager (SILHelpers)

- (HMAccessory *)findAccessoryWithServiceOfType:(NSString *)serviceType;

@end
