#import <UIKit/UIKit.h>

#import "GCDAsyncSocket.h"

@class GCDAsyncSocket;

@interface SimpleHTTPClientViewController : UIViewController<GCDAsyncSocketDelegate> {
    GCDAsyncSocket *asyncSocket;
}

@end
