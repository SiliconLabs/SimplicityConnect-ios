//
//  IUdpServer.h
//  BlueGecko
//
//  Created by SovanDas Maity on 06/09/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IUdpServer <NSObject>
-(void)OnReceiveDataError:(NSError*)err;
-(void)OnDidReadDataSuccess:(NSData *)data;
-(void)udpSocketDidClose:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
