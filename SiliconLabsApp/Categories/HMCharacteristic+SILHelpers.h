//
//  HMCharacteristic+SILHelpers.h
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/12/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#if ENABLE_HOMEKIT
#import <HomeKit/HomeKit.h>
#endif

@interface HMCharacteristic (SILHelpers)

- (BOOL)isWritable;
- (BOOL)isReadable;
- (BOOL)hasProperty:(NSString *)property;

@end
