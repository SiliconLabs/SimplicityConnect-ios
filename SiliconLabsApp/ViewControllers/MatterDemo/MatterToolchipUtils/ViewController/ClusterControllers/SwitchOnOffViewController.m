//
//  SwitchOnOffViewController.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 03/10/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

#import "SwitchOnOffViewController.h"
#import "CHIPUIViewUtils.h"
#import "DefaultsUtils.h"
#import "DeviceSelector.h"
#import <Matter/Matter.h>

@interface SwitchOnOffViewController ()

@end

@implementation SwitchOnOffViewController
@synthesize  nodeId, endPoint;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupUIElements];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSDictionary* userInfo = @{@"controller": @"SwitchOnOffViewController"};
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
    
    NSInteger endpoint = 1;
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            
            if (@available(iOS 16.1, *)) {
                MTRBaseClusterOnOff * on = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                              endpoint:endpoint
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
        
    NSLog(@" stored nodeID:- %@", [[NSUserDefaults standardUserDefaults] valueForKey:@"device_ID"]);
    NSNumber *_deviceId = [[NSUserDefaults standardUserDefaults] valueForKey:@"device_ID"];
    uint64_t _devId = _deviceId.intValue;
    
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
        self.clusterImage.image = [UIImage imageNamed:@"lightOn"];
    } else {
        self.clusterImage.image = [UIImage imageNamed:@"lightOff"];
    }
}

@end
