//
//  NetTest.h
//  TCPConnectDemo
//
//  Created by HSDM10 on 2018/12/19.
//  Copyright © 2018年 HSDM10. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

NS_ASSUME_NONNULL_BEGIN

@protocol NetTestDelegate
@optional

-(void) onNetTestResult:(Boolean) result;
- (void)uploadFile:(long)fileCount;
- (void)uploadFileStatus:(Boolean)start;
-(void) onConnectionClose:(Boolean) status;
-(void) firmwaeUpdateStart:(Boolean) status;


@end

@interface NetTest : NSObject
@property (weak, nonatomic) id<NetTestDelegate> delegate;

- (NSString *)creatrCerver;
- (void)connect;
- (void)sendData;
- (void)closeSocket;
- (NSString *)getIPAddressesToDo:(BOOL)preferIPv4;
-(id)initWithPort:(int)portNumber fileData:(NSData *)fileDataValue hostIP:(NSString *)ipAddress;

@end

NS_ASSUME_NONNULL_END
