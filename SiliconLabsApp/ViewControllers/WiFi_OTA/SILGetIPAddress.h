//
//  SILGetIPAddress.h
//  BlueGecko
//
//  Created by Subhojit Mandal on 27/02/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SILGetIPAddress : NSObject
+(SILGetIPAddress *)sharedInstance;
- (NSString *)getIPAddressesToDo:(BOOL)preferIPv4;
- (NSDictionary *)getIPAddressesToDo;
@end

NS_ASSUME_NONNULL_END
