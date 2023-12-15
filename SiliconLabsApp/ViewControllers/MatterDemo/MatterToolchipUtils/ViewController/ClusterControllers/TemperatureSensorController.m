//
//  TemperatureSensorController.m
//  BlueGecko
//
//  Created by SovanDas Maity on 16/10/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

#import "TemperatureSensorController.h"
#import "CHIPUIViewUtils.h"
#import "DefaultsUtils.h"
#import "DeviceSelector.h"
#import <Matter/Matter.h>

@interface TemperatureSensorController ()

@end
static TemperatureSensorController * _Nullable sCurrentController = nil;

@implementation TemperatureSensorController
@synthesize  nodeId, endPoint;
NSMutableArray * temperatureDeviceList;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    temperatureDeviceList = [[NSMutableArray alloc] init];
    temperatureDeviceList = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    sCurrentController = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _deviceCurrentStatusLabel.hidden = YES;
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear: animated];
    [self readDevice];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSDictionary* userInfo = @{@"controller": @"TemperatureSensorController"};
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"controllerNotification"
     object:self userInfo:userInfo];
}

+ (nullable TemperatureSensorController *)currentController {
    return sCurrentController;
}

-(void)readTemperatureSensor {
    NSInteger endpointVal = endPoint.intValue;
    uint64_t _devId = nodeId.intValue;
    int minIntervalSeconds = 2;
    int maxIntervalSeconds = 5;
    //int deltaInCelsius = 0;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        
        if (chipDevice) {
            [chipDevice subscribeWithQueue:dispatch_get_main_queue()
                               minInterval:minIntervalSeconds
                               maxInterval:maxIntervalSeconds
                                    params:nil
                            cacheContainer:nil
                    attributeReportHandler:^(NSArray * _Nonnull values) {
                if (!values)
                    return;
                for (MTRAttributeReport * report in values) {
                    // These should be exposed by the SDK
                    if ([report.path.cluster isEqualToNumber:@(MTRClusterTemperatureMeasurementID)] &&
                        [report.path.attribute
                         isEqualToNumber:@(MTRClusterTemperatureMeasurementAttributeMeasuredValueID)]) {
                        if (report.error != nil) {
                            NSLog(@"Error reading temperature: %@", report.error);
                        } else {
                            NSLog(@"%d",((NSNumber *) report.value).shortValue);
                            //temperatureLbl
                            __auto_type controller = [TemperatureSensorController currentController];
                            if (controller != nil) {
                                [controller updateTempInUI:((NSNumber *) report.value).shortValue];
                            }
                        }
                    }
                }
                
            } eventReportHandler:^(NSArray * _Nonnull values) {
                
            } errorHandler:^(NSError * _Nonnull error) {
                NSLog(@"Status: update reportAttributeMeasuredValue completed with error %@", [error description]);
            } subscriptionEstablished:^{
                
            } resubscriptionScheduled:^(NSError * _Nonnull error, NSNumber * _Nonnull resubscriptionDelay) {
                
            }];
            
        } else {
            NSLog(@"Status: Failed to establish a connection with the device");
        }
    })) {
        NSLog(@"Status: Waiting for connection with the device");
    } else {
        NSLog(@"Status: Failed to trigger the connection with the device");
    }
}

- (void)updateTempInUI:(int)newTemp {
    double tempInCelsius = (double) newTemp / 100;
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 2;
    [formatter setRoundingMode:NSNumberFormatterRoundFloor];
    _temperatureLbl.text =
    [NSString stringWithFormat:@"%@ °C", [formatter stringFromNumber:[NSNumber numberWithFloat:tempInCelsius]]];
    NSLog(@"Status: Updated temp in UI to %@", _temperatureLbl.text);
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
            [self setDeviceStatus:@"0" nodeId:self->nodeId];
        }
    })) {
    } else {
        [self setDeviceStatus:@"0" nodeId:self->nodeId];
    }
}

- (void)setDeviceStatus:(NSString *)connected nodeId:(NSNumber *)node_id{
    //NSArray *filtered = [lockDeviceList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(nodeId == %@)", @(7)]];
    NSUInteger index2 = [temperatureDeviceList indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        BOOL found = [[item objectForKey:@"nodeId"] intValue] == node_id.intValue;
        return found;
    }];
    //NSLog(@" index2 ======== %d\n", index2);
    if([temperatureDeviceList count] > 0){
        NSNumber *nodeId = [temperatureDeviceList[index2] valueForKey:@"nodeId"];
        NSString *deviceType = [temperatureDeviceList[index2] valueForKey:@"deviceType"];
        
        NSMutableDictionary * deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:deviceType forKey:@"deviceType"];
        [deviceDic setObject:nodeId forKey:@"nodeId"];
        [deviceDic setObject:@1 forKey:@"endPoint"];
        [deviceDic setObject:connected forKey:@"isConnected"];
        [deviceDic setObject:[temperatureDeviceList[index2] valueForKey:@"title"] forKey:@"title"];

        [temperatureDeviceList replaceObjectAtIndex:index2 withObject:deviceDic];
    }
    [[NSUserDefaults standardUserDefaults] setObject:temperatureDeviceList forKey:@"saved_list"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"deviceListTemp:- %@",temperatureDeviceList);
    [SVProgressHUD dismiss];
    if([connected isEqualToString:@"0"]){
        [self showAlertPopup:@"Device is offline, Please check the device connectivity."];
    }else{
        [self readTemperatureSensor];
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
