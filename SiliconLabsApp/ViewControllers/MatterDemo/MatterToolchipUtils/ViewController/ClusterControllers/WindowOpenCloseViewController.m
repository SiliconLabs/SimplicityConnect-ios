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
MTRSubscribeParams * subParamWindow;
NSString *tiltValue;
NSString *liftValue;

- (void)viewDidLoad {
    [super viewDidLoad];
    windowDeviceList = [[NSMutableArray alloc] init];
    windowDeviceList = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    _liftInputTextField.delegate = self;
    _tiltInputTextField.delegate = self;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupUIElements];
    
    // Get intial value from board
    [self readLiftDeviceStatus];
    [self readTildDeviceStatus];

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
    
    _liftButton.layer.cornerRadius = 10;
    _liftButton.clipsToBounds = YES;
    
    _tiltButton.layer.cornerRadius = 10;
    _tiltButton.clipsToBounds = YES;
    
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

- (void) updateWindowLiftValue: (NSNumber *) liftValue {
    NSInteger endpointVal = endPoint.intValue;
    [self updateResult:[NSString stringWithFormat:@"Off command sent on endpoint %@", @(endpointVal)]];
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            if (@available(iOS 16.4, *)) {
                MTRBaseClusterWindowCovering *wind = [[MTRBaseClusterWindowCovering alloc] initWithDevice:chipDevice
                                                                                               endpointID:@(endpointVal)
                                                                                                    queue:dispatch_get_main_queue()];
                
                MTRWindowCoveringClusterGoToLiftPercentageParams *params = [[MTRWindowCoveringClusterGoToLiftPercentageParams alloc] init];
                
                params.liftPercent100thsValue = liftValue;
                // params.timedInvokeTimeoutMs = @20;
                // params.serverSideProcessingTimeout = @1000;
                
                [wind goToLiftPercentageWithParams: params completionHandler:^(NSError * _Nullable error) {
                    NSLog(@" Lift Button Tapped Responce");
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

- (void) updateWindowTiltValue: (NSNumber *) tiltValue {
    
    NSInteger endpointVal = endPoint.intValue;
    [self updateResult:[NSString stringWithFormat:@"Off command sent on endpoint %@", @(endpointVal)]];
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            if (@available(iOS 16.4, *)) {
                MTRBaseClusterWindowCovering *wind = [[MTRBaseClusterWindowCovering alloc] initWithDevice:chipDevice
                                                                                               endpointID:@(endpointVal)
                                                                                                    queue:dispatch_get_main_queue()];
                
                // Tilt %
                MTRWindowCoveringClusterGoToTiltPercentageParams *parm = [[MTRWindowCoveringClusterGoToTiltPercentageParams alloc] init];
                parm.tiltPercent100thsValue = tiltValue;
                [wind goToTiltPercentageWithParams: parm completionHandler:^(NSError * _Nullable error) {
                    NSLog(@"Tilt Button Tapped Responce");
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

// MARK: UIButton actions

- (IBAction)onButtonTapped:(id)sender {
    
    NSInteger endpointVal = endPoint.intValue;
    [self updateResult:[NSString stringWithFormat:@"On command sent on endpoint %@", @(endpointVal)]];
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            
            if (@available(iOS 16.1, *)) {
                MTRBaseClusterWindowCovering *wind = [[MTRBaseClusterWindowCovering alloc] initWithDevice:chipDevice
                                                                                                 endpoint:endpointVal
                                                                                                    queue:dispatch_get_main_queue()];
                
                if (@available(iOS 16.4, *)) {
                    [wind upOrOpenWithCompletion:^(NSError * _Nullable error) {
                        NSLog(@"open");
                        NSString * resultString = (error != nil)
                        ? [NSString stringWithFormat:@"An error occurred: 0x%02lx", error.code] : @"On";
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

- (IBAction)offButtonTapped:(id)sender {
    
    NSInteger endpointVal = endPoint.intValue;
    [self updateResult:[NSString stringWithFormat:@"Off command sent on endpoint %@", @(endpointVal)]];
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            
            if (@available(iOS 16.4, *)) {
                MTRBaseClusterWindowCovering *wind = [[MTRBaseClusterWindowCovering alloc] initWithDevice:chipDevice
                                                                                               endpointID:@(endpointVal)
                                                                                                    queue:dispatch_get_main_queue()];
                [wind downOrCloseWithCompletion:^(NSError * _Nullable error) {
                    NSLog(@"Close");
                    NSString * resultString = (error != nil)
                    ? [NSString stringWithFormat:@"An error occurred: 0x%02lx", error.code] : @"Off";
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

- (void) subscribeWindowStatus {
    
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
                
                [wind subscribeAttributeModeWithParams:subParamWindow subscriptionEstablished:^{
                } reportHandler:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                    NSLog(@"Updated window Value:- %@", value);
                }];
            } else {
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

- (void) updateWindowLiftUIStatus: (NSNumber *) liftValue {
    
    int windowListPosition = liftValue.intValue/100;
    switch (windowListPosition) {
        case 0 ... 10:
            self.clusterImage.image = [UIImage imageNamed:@"window_1"];
            break;
        case 11 ... 20:
            self.clusterImage.image = [UIImage imageNamed:@"window_2"];
            break;
        case 21 ... 30:
            self.clusterImage.image = [UIImage imageNamed:@"window_3"];
            break;
        case 31 ... 40:
            self.clusterImage.image = [UIImage imageNamed:@"window_4"];
            break;
        case 41 ... 50:
            self.clusterImage.image = [UIImage imageNamed:@"window_5"];
            break;
        case 51 ... 60:
            self.clusterImage.image = [UIImage imageNamed:@"window_6"];
            break;
        case 61 ... 70:
            self.clusterImage.image = [UIImage imageNamed:@"window_7"];
            break;
        case 71 ... 80:
            self.clusterImage.image = [UIImage imageNamed:@"window_8"];
            break;
        case 81 ... 90:
            self.clusterImage.image = [UIImage imageNamed:@"window_9"];
            break;
        case 91 ... 100:
            self.clusterImage.image = [UIImage imageNamed:@"window_10"];
            break;
    }
}

- (void) updateWindowTiltUIStatus: (NSNumber *) tiltValue {
    int windowTiltIntValue = tiltValue.intValue/100;
    
    switch (windowTiltIntValue) {
            
        case 0 ... 10:
            self.clusterImage.alpha = .1;
            break;
        case 11 ... 20:
            self.clusterImage.alpha = .15;
            break;
        case 21 ... 30:
            self.clusterImage.alpha = .25;
            break;
        case 31 ... 40:
            self.clusterImage.alpha = .35;
            break;
        case 41 ... 50:
            self.clusterImage.alpha = .45;
            break;
        case 51 ... 60:
            self.clusterImage.alpha = .55;
            break;
        case 61 ... 70:
            self.clusterImage.alpha = .65;
            break;
        case 71 ... 80:
            self.clusterImage.alpha = .75;
            break;
        case 81 ... 90:
            self.clusterImage.alpha = .85;
            break;
        case 91 ... 100:
            self.clusterImage.alpha = .95;
            break;
    }
}

- (IBAction)liftButtonAction:(id)sender {
    // 1000 mean 10% and 10000 mean 100%
    int _liftIntValue = (_liftInputTextField.text).intValue;
    
    NSNumber *liftValue = [NSNumber numberWithInt:_liftIntValue];
    
    if ([liftValue  isEqual: @""] || (_liftIntValue  > 100) || (_liftIntValue  == 0) )  {
        [self showAlertPopup:@"Please enter value between 1 - 100 to perform Lift Window Curtain." back: false ];
    } else {
        int value = _liftIntValue*100;
        int valueForLift = 10000 - value;
        NSNumber *liftValue = [NSNumber numberWithInt: valueForLift];
        [self updateWindowLiftValue: liftValue];
        [self readLiftDeviceStatus];
    }
}

- (IBAction)tiltButtonAction:(id)sender {
    // 1000 mean 10% and 10000 mean 100%
    int tiltIntValue = (_tiltInputTextField.text).intValue;
    NSNumber *tiltValue = [NSNumber numberWithInt:tiltIntValue];
    
    if ([tiltValue  isEqual: @""] || (tiltIntValue  > 100) || (tiltIntValue  == 0)) {
        [self showAlertPopup:@"Please enter value between 1 - 100 to perform Tilt Window Curtain." back: false];
    } else {
        int value = tiltIntValue*100;
        int valueForTilt = 10000 - value;
        NSNumber * tiltValue = [NSNumber numberWithInt: valueForTilt];
        [self updateWindowTiltValue: tiltValue];
        [self readTildDeviceStatus];
    }
}

// Update image Status
- (void) updateImageStatus: (BOOL) status {
    if (status == TRUE) {
        self.liftInputTextField.text = @"";
        self.liftInputTextField.text = @"";
        self.clusterImage.image = [UIImage imageNamed:@"window_0"];
    } else {
        self.liftInputTextField.text = @"";
        self.liftInputTextField.text = @"";
        self.clusterImage.image = [UIImage imageNamed:@"window_10"];
    }
    self.clusterImage.alpha = 1;
}

-(void) readTildDeviceStatus {
    NSInteger endpoint = 1;
    uint64_t _devId = nodeId.intValue;
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            MTRBaseClusterDescriptor * descriptorCluster =
            [[MTRBaseClusterDescriptor alloc] initWithDevice:chipDevice
                                                    endpoint:1
                                                       queue:dispatch_get_main_queue()];
            
            MTRBaseClusterWindowCovering *wind = [[MTRBaseClusterWindowCovering alloc] initWithDevice:chipDevice endpoint:endpoint queue:dispatch_get_main_queue()];
            
            [wind readAttributeTargetPositionTiltPercent100thsWithCompletionHandler:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                NSLog(@"Tilt Percent position: %@", value);
                [self updateWindowTiltUIStatus: value];
                if (error) {
                    [self setDeviceStatus:@"0" nodeId:self->nodeId];
                    return;
                }
            }];
        } else {
        }
    })) {
        [self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
    }
}

-(void) readLiftDeviceStatus {
    NSInteger endpoint = 1;
    uint64_t _devId = nodeId.intValue;
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            MTRBaseClusterDescriptor * descriptorCluster =
            [[MTRBaseClusterDescriptor alloc] initWithDevice:chipDevice
                                                    endpoint:1
                                                       queue:dispatch_get_main_queue()];
            
            MTRBaseClusterWindowCovering *wind = [[MTRBaseClusterWindowCovering alloc] initWithDevice:chipDevice endpoint:endpoint queue:dispatch_get_main_queue()];
            
            [wind readAttributeTargetPositionLiftPercent100thsWithCompletionHandler:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                NSLog(@"Lift Percent position: %@", value);
                [self updateWindowLiftUIStatus: value];
                
                if (error) {
                    [self setDeviceStatus:@"0" nodeId:self->nodeId];
                    return;
                }
            }];
        } else {
            [self updateResult:[NSString stringWithFormat:@"Failed to establish a connection with the device"]];
        }
    })) {
        [self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
        //[self setDeviceStatus:@"0" nodeId:self->nodeId];
        // [self updateResult:[NSString stringWithFormat:@"Failed to trigger the connection with the device"]];
    }
}

- (void)setDeviceStatus:(NSString *)connected nodeId:(NSNumber *)node_id{
    NSUInteger index2 = [windowDeviceList indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        BOOL found = [[item objectForKey:@"nodeId"] intValue] == node_id.intValue;
        return found;
    }];

    if([windowDeviceList count] > 0){
        NSNumber *nodeId = [windowDeviceList[index2] valueForKey:@"nodeId"];
        NSString *deviceType = [windowDeviceList[index2] valueForKey:@"deviceType"];
        
        NSMutableDictionary * deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:deviceType forKey:@"deviceType"];
        [deviceDic setObject:nodeId forKey:@"nodeId"];
        [deviceDic setObject:@1 forKey:@"endPoint"];
        [deviceDic setObject:connected forKey:@"isConnected"];
        [deviceDic setObject:[windowDeviceList[index2] valueForKey:@"title"] forKey:@"title"];
        
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @"false"] forKey:@"isBinded"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceType"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceName"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToNodeId"];

        [windowDeviceList replaceObjectAtIndex:index2 withObject:deviceDic];
    }
    [[NSUserDefaults standardUserDefaults] setObject:windowDeviceList forKey:@"saved_list"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"deviceListTemp:- %@",windowDeviceList);
    [SVProgressHUD dismiss];
    if([connected isEqualToString:@"0"]){
        [self showAlertPopup:@"Device is offline, Please check the device connectivity." back: true];
    }
}

- (void) showAlertPopup:(NSString *) message back: (BOOL) isBack {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message: message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isBack) {
                [self.navigationController popViewControllerAnimated: YES];
            }
        });
    }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

// MARK: TextField Delegates

- (BOOL)resignFirstResponder {
    return true;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    _windowViewTopConstraints.constant = 0;
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    _windowViewTopConstraints.constant = -10;
}

- (void) dismissKeyboard {
    [_liftInputTextField resignFirstResponder];
    [_tiltInputTextField resignFirstResponder];
    _windowViewTopConstraints.constant = 0;
}

@end
