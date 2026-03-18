//
//  EVSEModeUtils.h
//  BlueGecko
//
//  Created by Mantosh Kumar on 21/09/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EVSEModeUtils : NSObject
+ (NSString *)modeNameForModeValue:(NSNumber *)modeValue
                 fromSupportedModes:(NSArray *)supportedModes;
@end

NS_ASSUME_NONNULL_END
