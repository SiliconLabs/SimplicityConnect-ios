//
//  ITcpServer.h
//  SiliconLabsApp
//
//  Created by Subhojit Mandal on 09/08/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//
#import <Foundation/Foundation.h>

@protocol ITLS_TxServer <NSObject>

#pragma mark ITLS_TxServer

-(void)OnDidAcceptNewSocket:(GCDAsyncSocket *)newSocket;
-(void)OnDidConnectToHost:(NSString *)host port:(uint16_t)port;
-(void)OnDidReadData:(NSData *)data withTag:(long)tag;
-(void)OnSocketDidDisconnectWithError:(NSError *)err;
-(void)OnDidWriteDataWithTag:(long)tag;
-(void)OnConnectionSucess;
@end

