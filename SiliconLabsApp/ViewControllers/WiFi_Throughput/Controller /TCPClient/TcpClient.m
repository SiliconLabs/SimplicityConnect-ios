//
//  TcpClient.m
//  ConnectTest
//
//  Created by  SmallTask on 13-8-15.
//
//

#import "TcpClient.h"
#import "GCDAsyncSocket.h"


#define USE_SECURE_CONNECTION 0
#define ENABLE_BACKGROUNDING  0

#if USE_SECURE_CONNECTION
#define HOST @"www.paypal.com"
#define PORT 443
#else
#define HOST @"192.168.1.205"
#define PORT 55184
#endif

@implementation TcpClient
@synthesize asyncSocket;

+ (TcpClient *)sharedInstance;
{
    static TcpClient *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[TcpClient alloc] init];
    });
    
    return _sharedInstance;
}


-(id)init;
{
    self = [super init];
    recivedArray = [NSMutableArray arrayWithCapacity:10];
    return self;
}

-(void)setDelegate_ITcpClient:(id<ITcpClient>)_itcpClient;
{
    itcpClient = _itcpClient;
}

-(void)openTcpConnection:(NSString*)host port:(NSInteger)port;
{
   
	dispatch_queue_t mainQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
    
    [asyncSocket setAutoDisconnectOnClosedReadStream:NO];
	
#if USE_SECURE_CONNECTION
	{
		NSString *host = HOST;
		uint16_t port = PORT;
		
		DDLogInfo(@"Connecting to \"%@\" on port %hu...", host, port);
		self.viewController.label.text = @"Connecting...";
		
		NSError *error = nil;
		if (![asyncSocket connectToHost:@"www.paypal.com" onPort:port error:&error])
		{
			DDLogError(@"Error connecting: %@", error);
			self.viewController.label.text = @"Oops";
		}
	}
#else
	{

		NSError *error = nil;
		if (![asyncSocket connectToHost:host onPort:port error:&error])
		{
		
//			self.viewController.label.text = @"Oops";
		}
        

		
	}
#endif
    
}

-(void)writeString:(NSString*)datastr;
{
    NSString *requestStr = [NSString stringWithFormat:@"%@\r\n",datastr];
    
    NSData *requestData = [requestStr dataUsingEncoding:NSUTF8StringEncoding];
    [self writeData:requestData];
}

-(void)writeData:(NSData*)data;
{
    TAG_SEND++;
    [asyncSocket writeData:data withTimeout:-1. tag:TAG_SEND];
}

-(void)read;
{
    [asyncSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];

}

-(long)GetSendTag;
{
    return TAG_SEND;
}

-(long)GetRecivedTag;
{
    return TAG_RECIVED;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Socket Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"socket:%p didConnectToHost:%@ port:%hu", sock, host, port);

	
    NSLog(@"localHost :%@ port:%hu", [sock localHost], [sock localPort]);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->itcpClient OnConnectionSucess];
    });

    [self read];
	
#if USE_SECURE_CONNECTION
	{
#if ENABLE_BACKGROUNDING && !TARGET_IPHONE_SIMULATOR
		{
			
			[sock performBlock:^{
				if ([sock enableBackgroundingOnSocket])
					DDLogInfo(@"Enabled backgrounding on socket");
				else
					DDLogWarn(@"Enabling backgrounding failed!");
			}];
		}
#endif
		
		// Configure SSL/TLS settings
		NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:3];

		
		[settings setObject:@"www.paypal.com"
					 forKey:(NSString *)kCFStreamSSLPeerName];
		

		DDLogInfo(@"Starting TLS with settings:\n%@", settings);
		
		[sock startTLS:settings];

		
	}
#else
	{
		// Connected to normal server (HTTP)
		
#if ENABLE_BACKGROUNDING && !TARGET_IPHONE_SIMULATOR
		{
			// Backgrounding doesn't seem to be supported on the simulator yet
			
			[sock performBlock:^{
				if ([sock enableBackgroundingOnSocket])
					DDLogInfo(@"Enabled backgrounding on socket");
				else
					DDLogWarn(@"Enabling backgrounding failed!");
			}];
		}
#endif
	}
#endif
    
    
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    NSLog(@"socketDidSecure:%p", sock);
//	self.viewController.label.text = @"Connected + Secure";
	
	NSString *requestStr = [NSString stringWithFormat:@"GET / HTTP/1.1\r\nHost: %@\r\n\r\n", HOST];
	NSData *requestData = [requestStr dataUsingEncoding:NSUTF8StringEncoding];
	
	[sock writeData:requestData withTimeout:-1 tag:0];
	[sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"socket:%p didWriteDataWithTag:%ld", sock, tag);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->itcpClient OnSendDataSuccess:[NSString stringWithFormat:@"tag:%li",tag]];
    });
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"socket:%p didReadData:withTag:%ld", sock, tag);
	
	NSString *httpResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
    NSLog(@"HTTP Response:\n%@", httpResponse);
    
    TAG_RECIVED = tag;
    
    if(![httpResponse isEqualToString:@""])
        [recivedArray addObject:httpResponse];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //
        [self->itcpClient OnReciveData:httpResponse];
    });

    
    [self read];
    
    [self writeString:@""];
    
	
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	NSLog(@"socketDidDisconnect:%p withError: %@", sock, err);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->itcpClient OnConnectionError:err];
    });
}

- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock
{
    
}



- (void)read:(NSInteger)tag {
}

@end
