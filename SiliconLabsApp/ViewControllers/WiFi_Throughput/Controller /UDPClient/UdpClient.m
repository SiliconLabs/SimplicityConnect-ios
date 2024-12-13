//
//  UdpClient.m
//  BlueGecko
//
//  Created by SovanDas Maity on 02/09/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

#import "UdpClient.h"

@implementation UdpClient
@synthesize asyncUdpSocket;

+ (UdpClient *)sharedInstance;
{
    static UdpClient *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[UdpClient alloc] init];
    });
    
    return _sharedInstance;
}

-(id)init;
{
    self = [super init];
    recivedArray = [NSMutableArray arrayWithCapacity:10];
    TOTAL_TIME = 0;
    return self;
}
-(void)setDelegate_IUdpClient:(id<IUdpClient>)_iUdpClient{
    iUdpClient = _iUdpClient;
}
-(void)start
{
    timer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerFired) userInfo:nil repeats:YES];

}
-(void)timerFired
{
    NSLog(@"TOTAL_TIME :::: %ld", TOTAL_TIME);
    TOTAL_TIME++;
}

-(void)openUdpConnection:(NSString*)host port:(NSInteger)port sendData:(NSData*)data{
    TOTAL_TIME = 0;
    IPaddress = host;
    portNumber = port;
    NSError *error = nil;
  dispatch_queue_t mainQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    if (!asyncUdpSocket) {
        asyncUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
    }
    
    if (![asyncUdpSocket bindToPort:port error:&error]) {
        return;
    }
//    if (![asyncUdpSocket connectToHost:host onPort:port error:&error]) {
//        return;
//    }
    if (![asyncUdpSocket beginReceiving:&error]) {
        return;
    }
    //[self start];
    [self writeData:data totalTimeCount:1];

    //NSLog(@"isConnected :::: %d", [asyncUdpSocket isConnected]);

}


-(void)writeData:(NSData*)data totalTimeCount:(long) timeCount
{
    NSString *host = IPaddress;
    if ([host length] == 0)
    {
        //[self logError:@"Address required"];
        return;
    }
    
    int port = portNumber;
    if (port <= 0 || port > 65535)
    {
        //[self logError:@"Valid port required"];
        return;
    }

  
    if (timeCount < 30) {
            //[self->asyncUdpSocket sendData:dataMy withTimeout:1 tag:self->TAG_SEND];
            [self->asyncUdpSocket sendData:data toHost:IPaddress port:portNumber withTimeout:1 tag:self->TAG_SEND];
        NSLog(@"timeCount :::: %ld", timeCount);
            self->TAG_SEND++;
    }else{
        [self->asyncUdpSocket close];
        TOTAL_TIME = 0;
        [asyncUdpSocket setDelegate:nil];
        asyncUdpSocket = nil;
        //[timer invalidate];
        //timer = nil;
    }

}



- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address {
    NSString *myString = [[NSString alloc] initWithData:address encoding:NSASCIIStringEncoding];
    NSLog(@"didConnectToAddress ==== %@", address);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->iUdpClient OnConnectionSucess:myString];
    });
}
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError * _Nullable)error {
    NSLog(@"didNotConnect ==== %@", error);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->iUdpClient OnConnectionError:error];
    });
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error {
    NSLog(@"udpSocketDidClose withError ==== %@", error);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->iUdpClient udpSocketDidClose:error];
    });
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->iUdpClient OnSendDataSuccess:@"TAG_SEND" totalTime:TOTAL_TIME];
    });
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    // You could add checks here
    NSLog(@"FAILD++++++++++ === %ld", TAG_SEND);
    NSLog(@"didNotSendDataWithTag ++++++++++ === %@", error);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->iUdpClient OnSendDataError:error];
    });
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
                                               fromAddress:(NSData *)address
                                         withFilterContext:(id)filterContext
{
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (msg)
    {
        //[self logMessage:FORMAT(@"RECV: %@", msg)];
    }
    else
    {
        NSString *host = nil;
        uint16_t port = 0;
        [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
        
        //[self logInfo:FORMAT(@"RECV: Unknown message from: %@:%hu", host, port)];
    }
}


@end
