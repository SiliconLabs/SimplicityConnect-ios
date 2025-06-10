//
//  PlugViewController.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 11/10/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

#import "PlugViewController.h"
#import "CHIPUIViewUtils.h"
#import "DefaultsUtils.h"
#import "DeviceSelector.h"
#import <Matter/Matter.h>

@interface PlugViewController ()

@end

@implementation PlugViewController
@synthesize  nodeId, endPoint;
NSMutableArray * plugDeviceList;
MTRBaseClusterOnOff * onOffPlug;
MTRSubscribeParams * subParamPlug;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    plugDeviceList = [[NSMutableArray alloc] init];
    plugDeviceList = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    subParamPlug = [[MTRSubscribeParams alloc] initWithMinInterval:@2 maxInterval:@2];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupUIElements];
   
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self readDevice];
    //[self readCurrentStateFromDevice];
    //[self showAlertPopup:@"HELLO"];
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    NSDictionary* userInfo = @{@"controller": @"PlugViewController"};
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"controllerNotification"
     object:self userInfo:userInfo];
}

// MARK: UI Setup

- (void)setupUIElements {
    _onButton.layer.cornerRadius = 5;
    _onButton.clipsToBounds = YES;
    
    _offButton.layer.cornerRadius = 5;
    _offButton.clipsToBounds = YES;
    _deviceCurrentStatusLabel.hidden = YES;
}

- (void)updateResult:(NSString *)result {
    if([result  isEqual: @"On"]){
        [self updateImageStatus:TRUE];
    } else if ([result  isEqual: @"Off"]){
        [self updateImageStatus:FALSE];
    } else{
        //
    }
}

// MARK: UIButton actions

- (IBAction)onButtonTapped:(id)sender {
    
    NSInteger endpointVal = endPoint.intValue;
    uint64_t _devId = nodeId.intValue;
    [self updateResult:[NSString stringWithFormat:@"On command sent on endpoint %@", @(endpointVal)]];

    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            
            if (@available(iOS 16.1, *)) {
                MTRBaseClusterOnOff * on = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                              endpoint:endpointVal
                                                                                 queue:dispatch_get_main_queue()];
                
                if (@available(iOS 16.1, *)) {
                    [on onWithCompletionHandler:^(NSError * error) {
                        NSString * resultString = (error != nil)
                        ? [NSString stringWithFormat:@"An error occurred: 0x%02lx", error.code]
                        : @"On";
                        [self updateResult:resultString];
                    }];
                } else {
                    // Fallback on earlier versions
                }
            } else {
                // Fallback on earlier versions
            }
        } else {
            [self updateResult:[NSString stringWithFormat:@"Failed to establish a connection with the device"]];
        }
    })) {
        [self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
        [self updateResult:[NSString stringWithFormat:@"Failed to trigger the connection with the device"]];
    }
}

- (IBAction)offButtonTapped:(id)sender
{
    NSInteger endpoint = 1;
    [self updateResult:[NSString stringWithFormat:@"Off command sent on endpoint %@", @(endpoint)]];
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
                        
            if (@available(iOS 16.1, *)) {
                MTRBaseClusterOnOff * off = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                               endpoint:endpoint
                                                                                  queue:dispatch_get_main_queue()];
                [off offWithCompletionHandler:^(NSError * error) {
                    NSString * resultString = (error != nil)
                    ? [NSString stringWithFormat:@"An error occurred: 0x%02lx", error.code]
                    : @"Off";
                    [self updateResult:resultString];
                }];
            } else {
                // Fallback on earlier versions
            }
            
        } else {
            [self updateResult:[NSString stringWithFormat:@"Failed to establish a connection with the device"]];
        }
    })) {
        [self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
        [self updateResult:[NSString stringWithFormat:@"Failed to trigger the connection with the device"]];
    }
}

// Update image Status
- (void) updateImageStatus: (BOOL) status {
    if (status == TRUE) {
        self.clusterImage.image = [UIImage imageNamed:@"plug_icon"];
    } else {
        self.clusterImage.image = [UIImage imageNamed:@"plugBord_icon"];
    }
}

-(void) readDevice {
    NSInteger endpoint = 1;
    uint64_t _devId = nodeId.intValue;
    [SVProgressHUD showWithStatus: @"Connecting to commissioned device..."];
   
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            MTRBaseClusterDescriptor * descriptorCluster =
            [[MTRBaseClusterDescriptor alloc] initWithDevice:chipDevice
                                                    endpoint:1
                                                       queue:dispatch_get_main_queue()];
            
            [descriptorCluster readAttributeDeviceListWithCompletionHandler:^(NSArray * _Nullable value, NSError * _Nullable error) {
                if (error) {
                    [self setDeviceStatus:@"0" nodeId:self->nodeId];
                    //[self showAlertMessage: errorMessage];
                    return;
                }
                [self setDeviceStatus:@"1" nodeId:self->nodeId];
            }];
            
            
            MTRBaseClusterOnOff * onOff = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                             endpoint:endpoint
                                                                                queue:dispatch_get_main_queue()];
            [onOff readAttributeOnOffWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                NSLog(@"chipDevice %@", value);
                if ([value  isEqual: @1]) {
                    [self updateResult:@"On"];
                } else {
                    [self updateResult:@"Off"];
                }
            }];
            
        } else {
            [self updateResult:[NSString stringWithFormat:@"Failed to establish a connection with the device"]];
            [self setDeviceStatus:@"0" nodeId:self->nodeId];
        }
    })) {
        [self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
        [self setDeviceStatus:@"0" nodeId:self->nodeId];
        [self updateResult:[NSString stringWithFormat:@"Failed to trigger the connection with the device"]];
    }
}

- (void)setDeviceStatus:(NSString *)connected nodeId:(NSNumber *)node_id{
    //NSArray *filtered = [lockDeviceList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(nodeId == %@)", @(7)]];
    NSUInteger index2 = [plugDeviceList indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        BOOL found = [[item objectForKey:@"nodeId"] intValue] == node_id.intValue;
        return found;
    }];

    if([plugDeviceList count] > 0){
        NSNumber *nodeId = [plugDeviceList[index2] valueForKey:@"nodeId"];
        NSString *deviceType = [plugDeviceList[index2] valueForKey:@"deviceType"];
        
        NSMutableDictionary * deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:deviceType forKey:@"deviceType"];
        [deviceDic setObject:nodeId forKey:@"nodeId"];
        [deviceDic setObject:@1 forKey:@"endPoint"];
        [deviceDic setObject:connected forKey:@"isConnected"];
        [deviceDic setObject:[plugDeviceList[index2] valueForKey:@"title"] forKey:@"title"];

        [deviceDic setObject:[NSString stringWithFormat:@"%@", @"false"] forKey:@"isBinded"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceType"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceName"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToNodeId"];

        [plugDeviceList replaceObjectAtIndex:index2 withObject:deviceDic];
    }
    [[NSUserDefaults standardUserDefaults] setObject:plugDeviceList forKey:@"saved_list"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"deviceListTemp:- %@",plugDeviceList);
    [SVProgressHUD dismiss];
    if([connected isEqualToString:@"0"]){
        [self showAlertPopup:@"Device is offline, Please check the device connectivity."];
    }else{
        //[self readCurrentStateFromDevice];
        NSTimeInterval delayInSeconds = 5.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
          NSLog(@"Do some work");
           //[self readCurrentStateFromDevice];
        });
    }
}
-(void) readCurrentStateFromDevice {
     NSInteger endpoint = 1;
    uint64_t _devId = nodeId.intValue;
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
//            MTRBaseClusterOnOff * onOff = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
//                                                                             endpoint:endpoint
//                                                                                queue:dispatch_get_main_queue()];
//            MTRSubscribeParams * subParam = [[MTRSubscribeParams alloc] initWithMinInterval:@2 maxInterval:@5];

            [onOffPlug subscribeAttributeOnOffWithParams:subParamPlug subscriptionEstablished:^{
            } reportHandler:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                if ([value  isEqual: @1]) {
                    [self updateResult:@"On"];
                } else {
                    [self updateResult:@"Off"];
                }
            }];
            
        } else {
            [self updateResult:[NSString stringWithFormat:@"Failed to establish a connection with the device"]];
        }
    })) {
        [self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
        [self updateResult:[NSString stringWithFormat:@"Failed to trigger the connection with the device"]];
    }
}
-(void) showAlertPopup:(NSString *) message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message: message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Go back to with payload and add device
            [self.navigationController popViewControllerAnimated: YES];
            //[self readCurrentStateFromDevice];
        });
    }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
