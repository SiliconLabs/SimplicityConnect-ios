//
//  UdpServer.h
//  BlueGecko
//
//  Created by SovanDas Maity on 04/09/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"
#import "IUdpServer.h"
NS_ASSUME_NONNULL_BEGIN

@interface UdpServer : NSObject <GCDAsyncUdpSocketDelegate>
{
    id<IUdpServer> iUdpServer;
    int port;
    NSString *host;
    long TAG_SEND;
    BOOL isRunning;
    GCDAsyncUdpSocket *udpSocket;
//    NSTimer *timer;
//    long TOTAL_TIME;
    
}

+ (UdpServer *)sharedInstance;

-(void)setDelegate_IUdpServer:(id<IUdpServer>)_iUdpServer;
- (void)initUdpServer:(NSString*)host port:(NSInteger)port;
-(void)connectionClose;

@end

NS_ASSUME_NONNULL_END
