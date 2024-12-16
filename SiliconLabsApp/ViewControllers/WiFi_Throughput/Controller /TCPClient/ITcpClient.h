//
//  ITcpClient.h
//  ConnectTest
//
//  Created by  SmallTask on 13-8-22.
//
//

#import <Foundation/Foundation.h>

@protocol ITcpClient <NSObject>

#pragma mark ITcpClient


-(void)OnSendDataSuccess:(NSString*)sendedTxt;


-(void)OnReciveData:(NSString*)recivedTxt;


-(void)OnConnectionError:(NSError *)err;

-(void)OnConnectionSucess;

@end
