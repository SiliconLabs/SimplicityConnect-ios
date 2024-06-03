//
//  NetTest.m
//  BlueGecko
//
//  Created by Subhojit Mandal on 26/02/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

#import "NetTest.h"
#import "GCDAsyncSocket.h"

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
//#define IOS_VPN       @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"
#define RPS_HEADER 0x01
#define RPS_DATA   0x00
@interface NetTest ()<GCDAsyncSocketDelegate>
{
    int port;
    NSString *host;
    long TAG_SEND;
}

@property (strong, nonatomic)GCDAsyncSocket * sock;
@property (strong, nonatomic)GCDAsyncSocket * serverSocket;
@property (strong, nonatomic)GCDAsyncSocket * clientSocket;
@property (strong, nonatomic)GCDAsyncSocket * clientSockets;

@end

@implementation NetTest


NSUInteger chunkSize = 0;
NSUInteger offset = 0;
NSUInteger firstTime = 0;
NSUInteger firstStart = 0;
NSInteger count = 0;
char data1[1500];
NSURL *fileURLVal;
NSData *data;


- (id)init {

    return [self initWithPort:5000 fileData:[NSData init] hostIP:@""];
}
-(id)initWithPort:(int)portNumber fileData:(NSData *)fileDataValue hostIP:(NSString *)ipAddress
{
     self = [super init];
     if (self) {
         NSLog(@"%d", portNumber);
//         host = [self getIPAddressesToDo:YES];
         host = ipAddress;

         if (!host) {
             host = @"127.0.0.1";
         }
         port = portNumber;
         //fileURLVal = fileURL;
         data = fileDataValue;
         NSLog(@"ipStr: %@ port:%d",host,port);

     }
     return self;
}

- (NSString *)creatrCerver {
    self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self      delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    NSError * error = nil;
    [self.serverSocket acceptOnPort:port error:&error];

    if (error) {
        NSLog(@"initAsyncSocket [error description]:%@", [error description]);
        if (self.delegate) {
            [self.delegate onNetTestResult:false];
        }
    } else {
        NSLog(@"Tcp Server Listen...");
    }
    return  host;
}

- (void)socketABC:(NSString *)sock{
    
   
}

- (void)closeSocket{
    [self.sock setDelegate:nil];
    [self.serverSocket setDelegate:nil];
    [self.clientSocket setDelegate:nil];
    [self.clientSockets setDelegate:nil];
 
    [self.sock disconnect];
    [self.serverSocket disconnect];
    [self.clientSocket disconnect];
    [self.clientSockets disconnect];
}

- (void)connect {
    self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    NSError *error = nil;
    [self.clientSocket connectToHost:host onPort:port error:&error];
    if (error) {
        NSLog(@"Connect failed! host=%@, port=%d, error=%@", host, port, error);
        if (self.delegate) {
            [self.delegate onNetTestResult:false];
        }
    }
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString * receive = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"GCDAsyncSocket receive:%@ receive.length:%lu", receive, (unsigned long)receive.length);
    NSLog(@"%@", data);
    if ([data length] > 0){
        
        NSMutableString *RPS_info = [NSMutableString string];
        const char *bytes = [data bytes];
    
       [RPS_info appendFormat:@"%02hhx", (unsigned char)bytes[0]];

        if ([RPS_info  isEqual: @"01"]){
            
            
          chunkSize = 0;
          offset = 0;
          firstTime = 0;
          count = 0;
            
            if (firstStart == 0){
                
                firstStart = 1;
                
                NSLog(@"Reset Pointer");
                if (self.delegate) {
                    [self.delegate firmwaeUpdateStart:true];
                }
                
            }
            
           
        }
        
        
    }
    [sock readDataWithTimeout:-1 tag:0];
    
    self.sock = sock;
   
    if (self.delegate) {
        [self.delegate uploadFileStatus:TRUE];
    }

    
}



- (void)sendData{

    NSUInteger length = [data length];
    
    NSLog(@"Total lenght %lu", length);
    
    
    
    
    if (firstTime == 0){
        firstTime = 1;
        chunkSize = 64;
        NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
        NSData* chunk = [NSData dataWithBytesNoCopy:(char *)[data bytes] + offset
                                             length:thisChunkSize
                                       freeWhenDone:NO];
        offset += thisChunkSize;
        NSLog(@"chunkSize : %lu", (unsigned long)chunkSize);
        //  NSLog(@"%@", chunk);
        NSLog(@"Data Read from file : %lu", (unsigned long)chunk.length);
        
        data1[0] = RPS_HEADER;
        data1[1] = (chunk.length & 0xff);
        data1[2] = ((chunk.length >> 8) & 0xff);
        
        
        NSLog(@"RPS_HEADER data1[0] : %x", data1[0]);
        NSLog(@"RPS_HEADER data1[1] : %x", data1[1]);
        NSLog(@"RPS_HEADER data1[2] : %x", data1[2]);
        
        NSUInteger size = 3;
        NSData* first3 = [NSData dataWithBytes:(const void *)data1 length:sizeof(unsigned char)*size];
        
        
        NSMutableData *completeData = [first3 mutableCopy];
        [completeData appendData:chunk];
        
        
        NSLog(@"completeData Size : %lu", (unsigned long)completeData.length);
        
        
        
        [self.sock writeData:completeData withTimeout:-1 tag:TAG_SEND];
        
        
        
        offset = 0;
    }else{
        chunkSize = 1024;
        
        NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
        NSData* chunk = [NSData dataWithBytesNoCopy:(char *)[data bytes] + offset
                                             length:thisChunkSize
                                       freeWhenDone:NO];
        offset += thisChunkSize;
        NSLog(@"%lu", (unsigned long)chunkSize);
        // NSLog(@"%@", chunk);
        NSLog(@"%lu", (unsigned long)chunk.length);
        
        data1[0] = RPS_DATA;
        data1[1] = (chunk.length & 0xff);
        data1[2] = ((chunk.length >> 8) & 0xff);
        
        
        
        NSLog(@"RPS_HEADER data1[0] : %x", data1[0]);
        NSLog(@"RPS_HEADER data1[1] : %x", data1[1]);
        NSLog(@"RPS_HEADER data1[2] : %x", data1[2]);
        
        
        NSUInteger size = 3;
        NSData* first3 = [NSData dataWithBytes:(const void *)data1 length:sizeof(unsigned char)*size];
        
        NSMutableData *completeData = [first3 mutableCopy];
        [completeData appendData:chunk];
        
        
        
        [self.sock writeData:completeData withTimeout:-1 tag:TAG_SEND];
        
        NSLog(@"completeData Size : %lu", (unsigned long)completeData.length);
        
        count++;
    }
    
    NSLog(@"Packet count %ld ",(long)count);
    
    if (self.delegate) {
        [self.delegate uploadFile:count];
    }
    
}



- (void)test {

     // Put a picture named "test.jpg" in your app bundle
     NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"jpg"];
     NSData *data = [NSData dataWithContentsOfFile:path];
     char buffer[data.length];

     // Print them out
     [data getBytes:buffer length:data.length];
     for (int i = 0; i < data.length; i++) {
         printf("%x ",(unsigned char)buffer[i]);
     }
 }


#pragma mark- GCDAsyncserverSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    self.clientSockets = newSocket;
    NSLog(@"GCDAsyncSocket:didAcceptNewSocket");
    [newSocket readDataWithTimeout:-1 tag:0];
    
    if (self.delegate) {
        [self.delegate onNetTestResult:true];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"didConnectToHost host=%@ port=%d", host, port);
    //[sock writeData:[@"connect teststr" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1. tag:TAG_SEND];
}




- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err;
{
    NSLog(@"socketDidDisconnect socket=%@, error=%@", sock, err);
    if (sock == self.clientSocket && err) {
        if (self.delegate) {
            [self.delegate onNetTestResult:false];
        }
    }else{
        NSLog(@"socketDidDisconnect with error");
        if (self.delegate) {
            [self.delegate onConnectionClose:true];
        }
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"didWriteDataWithTag tag:%ld",tag);
}

#pragma mark - IP地址
//获取设备当前网络IP地址
- (NSString *)getIPAddressesToDo:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
    @[ /*IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6,*/ IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ /*IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4,*/ IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddressesToDo];
    NSLog(@"addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         if(address) *stop = YES;
     } ];
    return address ? address : @"0.0.0.0";
}

//获取所有相关IP信息
- (NSDictionary *)getIPAddressesToDo
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                    
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}
@end
