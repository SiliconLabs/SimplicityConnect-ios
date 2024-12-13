//
//  UdpClient.h
//  BlueGecko
//
//  Created by SovanDas Maity on 02/09/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"
#import "IUdpClient.h"
NS_ASSUME_NONNULL_BEGIN

@interface UdpClient : NSObject
{
    long TAG_SEND;
    long TAG_RECIVED;
    
    
    id<IUdpClient> iUdpClient;
    
    NSMutableArray *recivedArray;
    NSTimer *timer;
    long TOTAL_TIME;
    NSString *IPaddress;
    NSInteger portNumber;
}

@property (nonatomic,retain) GCDAsyncUdpSocket *asyncUdpSocket;

+ (UdpClient *)sharedInstance;
-(void)setDelegate_IUdpClient:(id<IUdpClient>)_iUdpClient;
-(void)openUdpConnection:(NSString*)host port:(NSInteger)port sendData:(NSData*)data;
-(void)writeData:(NSData*)data totalTimeCount:(long) timeCount;

@end

NS_ASSUME_NONNULL_END
