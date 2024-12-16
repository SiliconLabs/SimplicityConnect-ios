//
//  SILTCPServerHelper.swift
//  BlueGecko
//
//  Created by Subhojit Mandal on 09/08/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.

#import <Foundation/Foundation.h>
#import "ITcpServer.h"

NS_ASSUME_NONNULL_BEGIN

//@protocol TCPServerDelegate
//@optional
//-(void) onNetTestResult:(Boolean) result;
//@end

@interface TCPServer : NSObject
{
    id<ITcpServer> itcpServer;
}

//@property (weak, nonatomic) id<TCPServerDelegate> delegate;
+ (TCPServer *)sharedInstance;

-(void)setDelegateITcpServer:(id<ITcpServer>)_itcpServer;

-(id)initWithPort:(int)portNumber hostIP:(NSString *)ipAddress;
- (void)creatrCerver;
- (void)connect;
- (void)sendData;
- (void)closeSocket;

@end

NS_ASSUME_NONNULL_END


