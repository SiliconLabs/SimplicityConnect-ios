//
//  SILTCPServerHelper.swift
//  BlueGecko
//
//  Created by Subhojit Mandal on 09/08/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.

#import <Foundation/Foundation.h>
#import "ITLS_TxServer.h"

NS_ASSUME_NONNULL_BEGIN

//@protocol TCPServerDelegate
//@optional
//-(void) onNetTestResult:(Boolean) result;
//@end

@interface TLS_Tx : NSObject
{
    id<ITLS_TxServer> iTLS_TxServer;
}

//@property (weak, nonatomic) id<TCPServerDelegate> delegate;
+ (TLS_Tx *)sharedInstance;

-(void)setDelegateI_TLS_TxServer:(id<ITLS_TxServer>)_iTLS_TxServer;

-(id)initWithPort:(int)portNumber hostIP:(NSString *)ipAddress;
- (void)creatrCerver;
- (void)connect;
- (void)sendData;
- (void)closeSocket;
-(void)writeData:(NSData*)data;

@end

NS_ASSUME_NONNULL_END


