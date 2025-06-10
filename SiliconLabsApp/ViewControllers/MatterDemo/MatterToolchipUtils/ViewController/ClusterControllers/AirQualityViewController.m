//
//  AirQualityViewController.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 07/02/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

#import "AirQualityViewController.h"
#import "CHIPUIViewUtils.h"
#import "DefaultsUtils.h"
#import "DeviceSelector.h"
#import <Matter/Matter.h>
#import "MatterHomeViewController.h"

typedef NS_ENUM(NSInteger, AirQualityType) {
    unknown = 0,
    good = 1,
    poor = 2,
    fair = 3,
    moderate = 4,
    vPoor = 5,
    ePoor = 6,
};

@interface AirQualityViewController ()
@property (strong, nonatomic) NSTimer *airQualityRefreshTimer;

@end

@implementation AirQualityViewController
@synthesize  nodeId, endPoint;
NSString * airValue;
NSMutableArray * deviceListAirQuality;

- (void)viewDidLoad {
    [super viewDidLoad];
        deviceListAirQuality = [[NSMutableArray alloc] init];
        deviceListAirQuality = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    [self readDevice];
    [self autoRefress];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _bgView.layer.cornerRadius = 10;
    _bgView.clipsToBounds = YES;
    
    [self setupUIElements];
    [self readAirQUalityData];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if ([_airQualityRefreshTimer isValid]) {
        [_airQualityRefreshTimer invalidate];
    }
    _airQualityRefreshTimer = nil;
    NSDictionary* userInfo = @{@"controller": @"AirQualityViewController"};
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"controllerNotification"
     object:self userInfo:userInfo];
}

// MARK: UI Setup

- (void)setupUIElements {
    _refressButton.layer.cornerRadius = 5;
    _refressButton.clipsToBounds = YES;
}

- (void)updateTempInUI:(int)newTemp {
    
    double tempInCelsius = (double) newTemp / 100;
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 2;
    [formatter setRoundingMode:NSNumberFormatterRoundFloor];
    _airQualityValueLabel.text =
    [NSString stringWithFormat:@"%@ °C", [formatter stringFromNumber:[NSNumber numberWithFloat: tempInCelsius]]];
}

- (void)readAirQUalityData {
    NSInteger endpointVal = endPoint.intValue;
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        
        if (chipDevice) {
            
            MTRBaseClusterTemperatureMeasurement * cluster =
            [[MTRBaseClusterTemperatureMeasurement alloc] initWithDevice:chipDevice
                                                                endpoint:endpointVal
                                                                   queue:dispatch_get_main_queue()];
            
            if (@available(iOS 16.4, *)) {
                MTRBaseClusterAirQuality * airQuality = [[MTRBaseClusterAirQuality alloc] initWithDevice:chipDevice endpointID:@1 queue:dispatch_get_main_queue()];
                
                MTRSubscribeParams *parm = [[MTRSubscribeParams alloc]init];
                parm.minInterval = @5;
                parm.maxInterval = @10000.0;
                [airQuality subscribeAttributeAirQualityWithParams: parm subscriptionEstablished:^ {
                    //
                } reportHandler:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                    airValue = [NSString stringWithFormat:@" AQI: %d", value.intValue];
                    NSLog(@"Air Quality Value:  %@", value);
                    self->_airQualityValueLabel.text = airValue;
                    [self updateAirQualityStatus: value.intValue];
                }];
                
            } else {
                // Fallback on earlier versions
            }
        } else {
            NSLog(@"Status: Failed to establish a connection with the device");
            //[self setDeviceStatus:@"0" nodeId:self->nodeId];
        }
    })) {
        NSLog(@"Status: Waiting for connection with the device");
    } else {
        NSLog(@"Status: Failed to trigger the connection with the device");
        //[self setDeviceStatus:@"0" nodeId:self->nodeId];
    }
}

- (void) updateAirQualityStatus:(int)type {
    
    AirQualityType airQuality = type;
    
    switch (airQuality) {
        case unknown:
            self.airQualityStatus.text = @"Unknown Quality";
        case good:
            self.airQualityStatus.text = @"Good Quality";
            break;
        case poor:
            self.airQualityStatus.text = @"Fair Quality";
            break;
        case fair:
            self.airQualityStatus.text = @"Moderate Quality";
            break;
        case moderate:
            self.airQualityStatus.text = @"Poor Quality";
            break;
        case vPoor:
            self.airQualityStatus.text = @"Very Poor Quality";
            break;
        case ePoor:
            self.airQualityStatus.text = @"Emergency Poor Quality";
            break;
        default:
            self.airQualityStatus.text = @"Unknown Quality";
            break;
    }
}

// MARK: UIButton actions

- (IBAction)refressAction:(id)sender {
    [self readAirQUalityData];
}

- (void) getCurrentreadAirQUalityData:(NSTimer *)timer {
    [self readAirQUalityData];
}

#pragma mark - Timers

- (void)autoRefress {
    self.airQualityRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                                   target:self selector:@selector(getCurrentreadAirQUalityData:) userInfo:nil repeats:YES];
}


- (void) readDevice {
    NSInteger endpoint = 1;
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            MTRBaseClusterDescriptor * descriptorCluster =
            [[MTRBaseClusterDescriptor alloc] initWithDevice:chipDevice
                                                    endpoint:1
                                                       queue:dispatch_get_main_queue()];
            
            [descriptorCluster readAttributeDeviceListWithCompletionHandler:^(NSArray * _Nullable value, NSError * _Nullable error) {
                if (error) {
                    [self setDeviceStatus:@"0" nodeId:self->nodeId];
                    return;
                }
                [self setDeviceStatus:@"1" nodeId:self->nodeId];
            }];
            
        } else {
            // [self setDeviceStatus:@"0" nodeId:self->nodeId];
        }
    })) {
    } else {
        // [self setDeviceStatus:@"0" nodeId:self->nodeId];
    }
}

- (void)setDeviceStatus:(NSString *)connected nodeId:(NSNumber *)node_id {
    NSUInteger index2 = [deviceListAirQuality indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        BOOL found = [[item objectForKey:@"nodeId"] intValue] == node_id.intValue;
        return found;
    }];

    if([deviceListAirQuality count] > 0){
        NSNumber *nodeId = [deviceListAirQuality[index2] valueForKey:@"nodeId"];
        NSString *deviceType = [deviceListAirQuality[index2] valueForKey:@"deviceType"];

        NSMutableDictionary * deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:deviceType forKey:@"deviceType"];
        [deviceDic setObject:nodeId forKey:@"nodeId"];
        [deviceDic setObject:@1 forKey:@"endPoint"];
        [deviceDic setObject:connected forKey:@"isConnected"];
        [deviceDic setObject:[deviceListAirQuality[index2] valueForKey:@"title"] forKey:@"title"];
        
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @"false"] forKey:@"isBinded"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceType"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceName"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToNodeId"];

        [deviceListAirQuality replaceObjectAtIndex:index2 withObject:deviceDic];
    }
    [[NSUserDefaults standardUserDefaults] setObject:deviceListAirQuality forKey:@"saved_list"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"deviceListTemp:- %@",deviceListAirQuality);
    [SVProgressHUD dismiss];
    if([connected isEqualToString:@"0"]){
        [self showAlertPopup:@"Device is offline, Please check the device connectivity."];
    }
}

- (void) showAlertPopup:(NSString *) message {
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
