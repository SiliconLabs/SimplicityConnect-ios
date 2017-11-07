//
//  HMAccessory+SILHelpers.h
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/12/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#if ENABLE_HOMEKIT
#import <HomeKit/HomeKit.h>
#endif

@interface HMAccessory (SILHelpers)

- (HMService *)findServiceOfType:(NSString *)serviceType;

@end
