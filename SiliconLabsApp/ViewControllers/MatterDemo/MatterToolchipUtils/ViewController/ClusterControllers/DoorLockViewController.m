//
//  DoorLockViewController.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 03/10/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

#import "DoorLockViewController.h"
#import "CHIPUIViewUtils.h"
#import "DefaultsUtils.h"
#import "DeviceSelector.h"
#import <Matter/Matter.h>

@interface DoorLockViewController ()

@end

@implementation DoorLockViewController
@synthesize  nodeId, endPoint, filterMainQueue;
NSMutableArray * lockDeviceList;
MTRBaseDevice * tempDevice;
MTRBaseClusterDoorLock * unlockLock;
MTRSubscribeParams * subParam;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    lockDeviceList = [[NSMutableArray alloc] init];
    lockDeviceList = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    subParam = [[MTRSubscribeParams alloc] initWithMinInterval:@2 maxInterval:@5];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupUIElements];
}
- (void)viewDidAppear:(BOOL)animated{
    [self readDevice];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSDictionary* userInfo = @{@"controller": @"DoorLockViewController"};
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"controllerNotification"
     object:self userInfo:userInfo];
}
-(void) readCurrentStateFromDevice {
     NSInteger endpoint = 1;
    uint64_t _devId = nodeId.intValue;
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            [unlockLock subscribeAttributeLockStateWithParams:subParam subscriptionEstablished:^{
            } reportHandler:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                    if([value isEqual:@2]){
                        [self updateResult:@"On"];
                    }else{
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
// MARK: UI Setup

- (void)setupUIElements {
    _doorOpenButton.layer.cornerRadius = 10;
    _doorOpenButton.clipsToBounds = YES;
    
    _doorLockButton.layer.cornerRadius = 10;
    _doorLockButton.clipsToBounds = YES;
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
    [self updateResult:[NSString stringWithFormat:@"On command sent on endpoint %@", @(endpointVal)]];
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            
            // DoorLock open
            [SVProgressHUD showWithStatus: @"InProgress..."];
                MTRBaseClusterDoorLock * unlockLock = [[MTRBaseClusterDoorLock alloc] initWithDevice:chipDevice
                                                                                            endpoint:endpointVal
                                                                                               queue:dispatch_get_main_queue()];
                
                MTRDoorLockClusterUnlockDoorParams * unlockParams = [[MTRDoorLockClusterLockDoorParams alloc] init];
                
                    [unlockLock unlockDoorWithParams:(unlockParams) completion:^(NSError * error) {
                        NSString * resultString = (error != nil)
                        ? [NSString stringWithFormat:@"An error occurred: 0x%02lx", error.code]
                        : @"On";
                        [self updateResult:resultString];
                        [SVProgressHUD dismiss];
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

- (IBAction)offButtonTapped:(id)sender
{
    NSInteger endpointVal = endPoint.intValue;
    [self updateResult:[NSString stringWithFormat:@"Off command sent on endpoint %@", @(endpointVal)]];
    uint64_t _devId = nodeId.intValue;
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
                        
            // DoorLock Close
            [SVProgressHUD showWithStatus: @"InProgress..."];
                MTRBaseClusterDoorLock * unlockLock = [[MTRBaseClusterDoorLock alloc] initWithDevice:chipDevice
                                                                                            endpoint:endpointVal
                                                                                               queue:dispatch_get_main_queue()];
                
                MTRDoorLockClusterUnlockDoorParams * unlockParams = [[MTRDoorLockClusterLockDoorParams alloc] init];
                
                [unlockLock lockDoorWithParams: unlockParams completion:^(NSError * error) {
                    NSString * resultString = (error != nil)
                    ? [NSString stringWithFormat:@"An error occurred: 0x%02lx", error.code]
                    : @"Off";
                    [self updateResult:resultString];
                    [SVProgressHUD dismiss];
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

// Update image Status
- (void) updateImageStatus: (BOOL) status {
    if (status == TRUE) {
        self.clusterImage.image = [UIImage imageNamed:@"lockOpen_icon"];
    } else {
        self.clusterImage.image = [UIImage imageNamed:@"lockClose_icon"];
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
            
             unlockLock = [[MTRBaseClusterDoorLock alloc] initWithDevice:chipDevice endpoint:endpoint queue:dispatch_get_main_queue()];
            [unlockLock readAttributeLockStateWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                NSLog(@"chipDevice %@", value);
                if ([value  isEqual: @2]) {
                   // [self updateResult:@"On"];
                } else {
                   // [self updateResult:@"Off"];
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
    NSUInteger index2 = [lockDeviceList indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        BOOL found = [[item objectForKey:@"nodeId"] intValue] == node_id.intValue;
        return found;
    }];
    //NSLog(@" index2 ======== %d\n", index2);
    if([lockDeviceList count] > 0){
        NSNumber *nodeId = [lockDeviceList[index2] valueForKey:@"nodeId"];
        NSString *deviceType = [lockDeviceList[index2] valueForKey:@"deviceType"];
        
        NSMutableDictionary * deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:deviceType forKey:@"deviceType"];
        [deviceDic setObject:nodeId forKey:@"nodeId"];
        [deviceDic setObject:@1 forKey:@"endPoint"];
        [deviceDic setObject:connected forKey:@"isConnected"];
        [deviceDic setObject:[lockDeviceList[index2] valueForKey:@"title"] forKey:@"title"];

        [lockDeviceList replaceObjectAtIndex:index2 withObject:deviceDic];
    }
    [[NSUserDefaults standardUserDefaults] setObject:lockDeviceList forKey:@"saved_list"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"deviceListTemp:- %@",lockDeviceList);
    [SVProgressHUD dismiss];
    if([connected isEqualToString:@"0"]){
        [self showAlertPopup:@"Device is offline, Please check the device connectivity."];
    }else{
        NSTimeInterval delayInSeconds = 5.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
          NSLog(@"Do some work");
            //[self readCurrentStateFromDevice];
        });
       
    }
}

-(void) showAlertPopup:(NSString *) message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message: message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.navigationController popViewControllerAnimated: YES];
            
           // [self readCurrentStateFromDevice];
            
            
        });
    }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
