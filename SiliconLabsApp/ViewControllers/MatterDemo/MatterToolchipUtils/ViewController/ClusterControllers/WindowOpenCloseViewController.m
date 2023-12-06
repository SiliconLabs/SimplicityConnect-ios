//
//  WindowOpenCloseViewController.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 03/10/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

#import "WindowOpenCloseViewController.h"
#import "CHIPUIViewUtils.h"
#import "DefaultsUtils.h"
#import "DeviceSelector.h"
#import <Matter/Matter.h>

@interface WindowOpenCloseViewController ()

@end

@implementation WindowOpenCloseViewController
@synthesize  nodeId, endPoint;
NSMutableArray * windowDeviceList;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //self.clusterImage.image = [UIImage imageNamed:@"windowOpen_icon"];
    windowDeviceList = [[NSMutableArray alloc] init];
    windowDeviceList = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    [self readDevice];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupUIElements];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSDictionary* userInfo = @{@"controller": @"WindowOpenCloseViewController"};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"controllerNotification" object:self userInfo:userInfo];
}

// MARK: UI Setup

- (void)setupUIElements {
    _openButton.layer.cornerRadius = 10;
    _openButton.clipsToBounds = YES;
    
    _closeButton.layer.cornerRadius = 10;
    _closeButton.clipsToBounds = YES;
    _deviceCurrentStatusLabel.hidden = YES;
}

- (void)updateResult:(NSString *)result {
    if([result  isEqual: @"On"]){
        [self updateImageStatus:TRUE];
    } else if ([result  isEqual: @"Off"]) {
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
            
            // Window Cover open
            
            if (@available(iOS 16.1, *)) {
                MTRBaseClusterWindowCovering *wind = [[MTRBaseClusterWindowCovering alloc] initWithDevice:chipDevice
                                                                                                 endpoint:endpointVal
                                                                                                    queue:dispatch_get_main_queue()];
                
                if (@available(iOS 16.4, *)) {
                    [wind upOrOpenWithCompletion:^(NSError * _Nullable error) {
                        NSLog(@"open");
                        NSString * resultString = (error != nil)
                        ? [NSString stringWithFormat:@"An error occurred: 0x%02lx", error.code]
                        : @"On";
                        [self updateResult:resultString];
                    }];
                } else {
                    // Fallback on earlier versions
                }
            } else {
                // if IOS version is < 16.1
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
    NSInteger endpointVal = endPoint.intValue;
    [self updateResult:[NSString stringWithFormat:@"Off command sent on endpoint %@", @(endpointVal)]];
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            
            // WindowCovering Close
            
            if (@available(iOS 16.4, *)) {
                MTRBaseClusterWindowCovering *wind = [[MTRBaseClusterWindowCovering alloc] initWithDevice:chipDevice
                                                                                               endpointID:@(endpointVal)
                                                                                                    queue:dispatch_get_main_queue()];
                [wind downOrCloseWithCompletion:^(NSError * _Nullable error) {
                    NSLog(@"Close");
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
        self.clusterImage.image = [UIImage imageNamed:@"windowOpen_icon"];
    } else {
        self.clusterImage.image = [UIImage imageNamed:@"windowClose_icon"];
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
            
            MTRBaseClusterWindowCovering *wind = [[MTRBaseClusterWindowCovering alloc] initWithDevice:chipDevice endpoint:endpoint queue:dispatch_get_main_queue()];
                        [wind readAttributeModeWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                            NSLog(@"chipDevice %@", value);
                        }];
            [wind readAttributeTargetPositionTiltPercent100thsWithCompletionHandler:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                NSLog(@"chipDevice %@", value);
//                if ([value  isEqual: @0]) {
//                    [self updateResult:@"On"];
//                } else {
//                    [self updateResult:@"Off"];
//                }
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
    NSUInteger index2 = [windowDeviceList indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        BOOL found = [[item objectForKey:@"nodeId"] intValue] == node_id.intValue;
        return found;
    }];
    //NSLog(@" index2 ======== %d\n", index2);
    if([windowDeviceList count] > 0){
        NSNumber *nodeId = [windowDeviceList[index2] valueForKey:@"nodeId"];
        NSString *deviceType = [windowDeviceList[index2] valueForKey:@"deviceType"];
        
        NSMutableDictionary * deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:deviceType forKey:@"deviceType"];
        [deviceDic setObject:nodeId forKey:@"nodeId"];
        [deviceDic setObject:@1 forKey:@"endPoint"];
        [deviceDic setObject:connected forKey:@"isConnected"];
        [deviceDic setObject:[windowDeviceList[index2] valueForKey:@"title"] forKey:@"title"];
        [windowDeviceList replaceObjectAtIndex:index2 withObject:deviceDic];
    }
    [[NSUserDefaults standardUserDefaults] setObject:windowDeviceList forKey:@"saved_list"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"deviceListTemp:- %@",windowDeviceList);
    [SVProgressHUD dismiss];
    if([connected isEqualToString:@"0"]){
        [self showAlertPopup:@"Device is offline, Please check the device connectivity."];
    }
}

-(void) showAlertPopup:(NSString *) message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message: message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Go back to with payload and add device
            [self.navigationController popViewControllerAnimated: YES];
        });
    }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}


@end
