//
//  UdpServer.m
//  BlueGecko
//
//  Created by SovanDas Maity on 04/09/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

#import "UdpServer.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

@implementation UdpServer

+ (UdpServer *)sharedInstance;
{
    static UdpServer *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[UdpServer alloc] init];
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

-(void)setDelegate_IUdpServer:(id<IUdpServer>)_iUdpServer{
    iUdpServer = _iUdpServer;
}
- (void)initUdpServer:(NSString*)host port:(NSInteger)port{

    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *error = nil;
    
    if (![udpSocket bindToPort:port error:&error])
    {
        return;
    }
    if (![udpSocket beginReceiving:&error])
    {
        [udpSocket close];
        return;
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address {
    NSString *myString = [[NSString alloc] initWithData:address encoding:NSASCIIStringEncoding];
    NSLog(@"didConnectToAddress ==== %@", address);
}
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError * _Nullable)error {
    NSLog(@"didNotConnect ==== %@", error);
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error {
    NSLog(@"udpSocketDidClose withError ==== %@", error);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->iUdpServer udpSocketDidClose:error];
    });
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
                                               fromAddress:(NSData *)address
                                         withFilterContext:(id)filterContext
{
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

   // NSLog(@"didReceiveData:::::: %id", isRunning);
//    NSLog(@"isClosed ================================ %d", [sock isClosed]);

    //if (!isRunning) return;
    
    //NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (msg)
    {
        //NSLog(@"didReceiveData:::::: %@", msg);
        /* If you want to get a display friendly version of the IPv4 or IPv6 address, you could do this:
         
        NSString *host = nil;
        uint16_t port = 0;
        [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
        
        */
        
        //[self logMessage:msg];
        dispatch_async(dispatch_get_main_queue(), ^{
            //[self->itcpServer OnDidReadData:data withTag:tag];
            [self->iUdpServer OnDidReadDataSuccess:data];
        });
    }
    else
    {
        //[self logError:@"Error converting received data into UTF-8 String"];
    }
    
    //[udpSocket sendData:data toAddress:address withTimeout:-1 tag:0];
}
- (void)connectionClose {
    [udpSocket close];
    //[self setDe];
    [udpSocket setDelegate:nil];
    udpSocket = nil;
}

#pragma mark - IP address

//Get the current network IP address of the device
- (NSString *)getIPAddressesToDo:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
    @[ /*IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6,*/ IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ /*IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4,*/ IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddressesToDo];
   // NSLog(@"addresses: %@", addresses);
    
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
