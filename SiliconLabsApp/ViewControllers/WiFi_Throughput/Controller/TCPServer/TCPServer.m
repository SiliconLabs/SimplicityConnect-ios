//
//  SILTCPServerHelper.swift
//  BlueGecko
//
//  Created by Subhojit Mandal on 09/08/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.

#import "TCPServer.h"
#import "GCDAsyncSocket.h"

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"
@interface TCPServer ()<GCDAsyncSocketDelegate>
{
    int port;
    NSString *host;
    long TAG_SEND;
}


@property (strong, nonatomic)GCDAsyncSocket * serverSocket;
@property (strong, nonatomic)GCDAsyncSocket * clientSocket;
@property (strong, nonatomic)GCDAsyncSocket * clientSockets;

@end

@implementation TCPServer

+ (TCPServer *)sharedInstance;
{
    static TCPServer *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[TCPServer alloc] init];
    });
    
    return _sharedInstance;
}
- (id)init {
    self = [super init];
    
    host = [self getIPAddressesToDo:YES];
    if (!host) {
        host = @"127.0.0.1";
    }
    port = 11000;
    NSLog(@"ipStr: %@ port:%d",host,port);
    
    return self;
}


-(id)initWithPort:(int)portNumber hostIP:(NSString *)ipAddress
{
     self = [super init];
     if (self) {
         NSLog(@"%d", portNumber);
         host = ipAddress;

         if (!host) {
             host = @"127.0.0.1";
         }
         port = portNumber;
         NSLog(@"ipStr: %@ port:%d",host,port);

     }
     return self;
}


-(void)setDelegateITcpServer:(id<ITcpServer>)_itcpServer;
{
    itcpServer = _itcpServer;
}

- (void)creatrCerver {
    self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self      delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    NSError * error = nil;
    [self.serverSocket acceptOnPort:port error:&error];

    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->itcpServer OnSocketDidDisconnectWithError:error];
        });

    } else {
        NSLog(@"Tcp Server Listen...");
    }
}

- (void)connect {
    self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    NSError *error = nil;
    [self.clientSocket connectToHost:host onPort:port error:&error];
    if (error) {
        NSLog(@"Connect failed! host=%@, port=%d, error=%@", host, port, error);
    }
}

- (void)sendData {
    [self.clientSocket writeData:[@"send teststrteststr" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1. tag:TAG_SEND];
}


- (void)closeSocket{
   
    [self.serverSocket setDelegate:nil];
    [self.clientSocket setDelegate:nil];
    [self.clientSockets setDelegate:nil];
    
    [self.serverSocket disconnect];
    [self.clientSocket disconnect];
    [self.clientSockets disconnect];
}

#pragma mark- GCDAsyncserverSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    self.clientSockets = newSocket;
    NSLog(@"GCDAsyncSocket:didAcceptNewSocket");
    [newSocket readDataWithTimeout:-1 tag:0];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self->itcpServer OnDidAcceptNewSocket:newSocket];
    });
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {

    dispatch_async(dispatch_get_main_queue(), ^{
        [self->itcpServer OnDidConnectToHost:host port:port];
    });
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [sock readDataWithTimeout:-1 tag:0];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->itcpServer OnDidReadData:data withTag:tag];
    });
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->itcpServer OnSocketDidDisconnectWithError:err];
    });
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->itcpServer OnDidWriteDataWithTag:tag];
    });
}

#pragma mark - IP address

//Get the current network IP address of the device
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

//Get all relevant IP information
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
