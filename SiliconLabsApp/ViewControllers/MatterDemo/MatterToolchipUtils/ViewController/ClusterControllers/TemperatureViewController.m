//
//  TemperatureViewController.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 03/10/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

#import "TemperatureViewController.h"
#import "CHIPUIViewUtils.h"
#import "DefaultsUtils.h"
#import "DeviceSelector.h"
#import <Matter/Matter.h>

static float kTempRefreshInterval = 0.2;

@interface TemperatureViewController ()
@property (strong, nonatomic) NSTimer *tempRefreshTimer;

@end

@implementation TemperatureViewController
@synthesize  nodeId, endPoint;
NSString * tempa;
NSMutableArray * deviceListTemperature;

- (void)viewDidLoad {
    [super viewDidLoad];
    deviceListTemperature = [[NSMutableArray alloc] init];
    deviceListTemperature = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    [self  readDevice];
    [self autoRefress];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _bgView.layer.cornerRadius = 10;
    _bgView.clipsToBounds = YES;
    
    [self setupUIElements];
    [self readThermos];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if ([_tempRefreshTimer isValid]) {
        [_tempRefreshTimer invalidate];
    }
    _tempRefreshTimer = nil;
    NSDictionary* userInfo = @{@"controller": @"TemperatureViewController"};
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"controllerNotification"
     object:self userInfo:userInfo];
}

// MARK: UI Setup

- (void)setupUIElements {
    _refressButton.layer.cornerRadius = 5;
    _refressButton.clipsToBounds = YES;
}

- (void)updateTempInUI:(int)newTemp
{
    double tempInCelsius = (double) newTemp / 100;
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 2;
    [formatter setRoundingMode:NSNumberFormatterRoundFloor];
    _tempValueLabel.text =
    [NSString stringWithFormat:@"%@ °C", [formatter stringFromNumber:[NSNumber numberWithFloat: tempInCelsius]]];
    NSLog(@"Status: Updated temp in UI to %@", _tempValueLabel.text);
    _deviceCurrentStatusLabel.hidden = YES;
}

- (void)readThermos {
    NSInteger endpointVal = endPoint.intValue;
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        
        if (chipDevice) {
            
            if (@available(iOS 16.1, *)) {
                MTRBaseClusterTemperatureMeasurement * cluster =
                [[MTRBaseClusterTemperatureMeasurement alloc] initWithDevice:chipDevice
                                                                    endpoint:endpointVal
                                                                       queue:dispatch_get_main_queue()];
            } else {
                // Fallback on earlier versions
            }
            
            if (@available(iOS 16.4, *)) {
                
                MTRBaseClusterThermostat * temp = [[MTRBaseClusterThermostat alloc] initWithDevice:chipDevice endpointID:@1 queue:dispatch_get_main_queue()];
                
                [temp readAttributeLocalTemperatureWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                    
                    float te = value.floatValue/100;
                    if(te - floor(te) > 0.49){
                        tempa = [NSString stringWithFormat:@"%d",value.intValue/100 + 1];
                    }else{
                        tempa = [NSString stringWithFormat:@"%d",value.intValue/100];
                    }
                    self->_tempValueLabel.text = [NSString stringWithFormat:@"%@ °C", tempa];
                    //[self setDeviceStatus:@"1" nodeId:self->nodeId];
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

// MARK: UIButton actions

- (IBAction)refressAction:(id)sender {
    [self readThermos];
}

- (void) getCurrentTemp:(NSTimer *)timer {
    [self readThermos];
}

#pragma mark - Timers

- (void)autoRefress {
    self.tempRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                             target:self selector:@selector(getCurrentTemp:) userInfo:nil repeats:YES];
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
            
        } else {
            //[self updateResult:[NSString stringWithFormat:@"Failed to establish a connection with the device"]];
            [self setDeviceStatus:@"0" nodeId:self->nodeId];
        }
    })) {
        //[self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
        [self setDeviceStatus:@"0" nodeId:self->nodeId];
        //[self updateResult:[NSString stringWithFormat:@"Failed to trigger the connection with the device"]];
    }
}
- (void)setDeviceStatus:(NSString *)connected nodeId:(NSNumber *)node_id{
    //NSArray *filtered = [lockDeviceList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(nodeId == %@)", @(7)]];
    NSUInteger index2 = [deviceListTemperature indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        BOOL found = [[item objectForKey:@"nodeId"] intValue] == node_id.intValue;
        return found;
    }];
    //NSLog(@" index2 ======== %d\n", index2);
    if([deviceListTemperature count] > 0){
        NSNumber *nodeId = [deviceListTemperature[index2] valueForKey:@"nodeId"];
        NSString *deviceType = [deviceListTemperature[index2] valueForKey:@"deviceType"];
        
        NSMutableDictionary * deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:deviceType forKey:@"deviceType"];
        [deviceDic setObject:nodeId forKey:@"nodeId"];
        [deviceDic setObject:@1 forKey:@"endPoint"];
        [deviceDic setObject:connected forKey:@"isConnected"];
        [deviceDic setObject:[deviceListTemperature[index2] valueForKey:@"title"] forKey:@"title"];
        
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @"false"] forKey:@"isBinded"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceType"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceName"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToNodeId"];

        [deviceListTemperature replaceObjectAtIndex:index2 withObject:deviceDic];
    }
    [[NSUserDefaults standardUserDefaults] setObject:deviceListTemperature forKey:@"saved_list"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"deviceListTemp:- %@",deviceListTemperature);
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
