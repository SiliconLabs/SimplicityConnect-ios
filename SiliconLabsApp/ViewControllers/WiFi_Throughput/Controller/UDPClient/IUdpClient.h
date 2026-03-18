//
//  IUdpClient.h
//  BlueGecko
//
//  Created by SovanDas Maity on 02/09/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IUdpClient <NSObject>
-(void)OnSendDataSuccess:(NSString*)sendedTxt totalTime:(long)totaltime;
-(void)OnSendDataError:(NSError*)err;
-(void)OnReciveData:(NSString*)recivedTxt;
-(void)OnConnectionError:(NSError *)err;
-(void)OnConnectionSucess:(NSString*)str;
-(void)udpSocketDidClose:(NSError *)error;
@end

NS_ASSUME_NONNULL_END
