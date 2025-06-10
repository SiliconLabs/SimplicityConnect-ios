//
//  ContactSensorViewController.m
//  BlueGecko
//
//  Created by SovanDas Maity on 16/10/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

#import "ContactSensorViewController.h"
#import "CHIPUIViewUtils.h"
#import "DefaultsUtils.h"
#import "DeviceSelector.h"
#import <Matter/Matter.h>

@interface ContactSensorViewController ()
@property (strong, nonatomic) NSTimer *tempRefreshTimer;

@end
static ContactSensorViewController * _Nullable cCurrentController = nil;

@implementation ContactSensorViewController

@synthesize  nodeId, endPoint;
NSMutableArray * contactDeviceList;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    contactDeviceList = [[NSMutableArray alloc] init];
    contactDeviceList = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    _contactImg.image = [UIImage imageNamed:@"ContactSensorOpen"];
    cCurrentController = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    //[self readContactSensor];
    _deviceCurrentStatusLabel.hidden = YES;
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear: animated];
    [self readDevice];
    [self autoRefress];
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if ([_tempRefreshTimer isValid]) {
        [_tempRefreshTimer invalidate];
    }
    _tempRefreshTimer = nil;
    
    NSDictionary* userInfo = @{@"controller": @"ContactSensorViewController"};
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"controllerNotification"
     object:self userInfo:userInfo];
}
+ (nullable ContactSensorViewController *)currentController
{
    return cCurrentController;
}

-(void)readContactSenserValue {
    NSInteger endpointVal = endPoint.intValue;
    uint64_t _devId = nodeId.intValue;
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            MTRBaseClusterBooleanState * booleanSt = [[MTRBaseClusterBooleanState alloc] initWithDevice:chipDevice endpoint:endpointVal queue:dispatch_get_main_queue()];
            
            [booleanSt readAttributeStateValueWithCompletionHandler:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                NSLog(@"%@", value);
                __auto_type controller = [ContactSensorViewController currentController];
                if (controller != nil) {
                    [controller updateTempInUI:value.intValue];
                }
            }];
        }
    })) {
        NSLog(@"Status: Waiting for connection with the device");
    } else {
        NSLog(@"Status: Failed to trigger the connection with the device");
    }
}

-(void)readContactSensor {
    NSInteger endpointVal = endPoint.intValue;
    uint64_t _devId = nodeId.intValue;
    int minIntervalSeconds = 2;
    int maxIntervalSeconds = 5;
    
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
                    
                    if ([report.path.attribute
                         isEqualToNumber:@(MTRClusterOccupancySensingAttributePhysicalContactOccupiedToUnoccupiedDelayID)]) {
                        if (report.error != nil) {
                            NSLog(@"Error reading temperature: %@", report.error);
                        } else {
                            NSLog(@"%d",((NSNumber *) report.value).shortValue);
                            //ClusterOccupancy
                            MTRBaseClusterOccupancySensing * cls = [[MTRBaseClusterOccupancySensing alloc] initWithDevice:chipDevice endpointID:@1 queue:dispatch_get_main_queue()];
                            [cls readAttributePhysicalContactOccupiedToUnoccupiedDelayWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                                NSLog(@"%@", value);
                            }];
                            
                            __auto_type controller = [ContactSensorViewController currentController];
                            if (controller != nil) {
                                [controller updateTempInUI:((NSNumber *) report.value).shortValue];
                            }
                        }
                    }else{
                        // Some error
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
    NSString *myString = [@(newTemp) stringValue];
    if ([myString isEqualToString:@"0"]) {
        _contactImg.image = [UIImage imageNamed:@"ContactSensorOpen"];
    } else {
        _contactImg.image = [UIImage imageNamed:@"ContactSensorClose"];
    }
}

- (void) getCurrentTemp:(NSTimer *)timer {
    [self readContactSenserValue];
}

#pragma mark - Timers

- (void)autoRefress {
    self.tempRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:2.0f
                                                             target:self
                                                           selector:@selector(getCurrentTemp:)
                                                           userInfo:nil repeats:YES];
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
    NSUInteger index2 = [contactDeviceList indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        BOOL found = [[item objectForKey:@"nodeId"] intValue] == node_id.intValue;
        return found;
    }];
    //NSLog(@" index2 ======== %d\n", index2);
    if([contactDeviceList count] > 0){
        NSNumber *nodeId = [contactDeviceList[index2] valueForKey:@"nodeId"];
        NSString *deviceType = [contactDeviceList[index2] valueForKey:@"deviceType"];
        
        NSMutableDictionary * deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:deviceType forKey:@"deviceType"];
        [deviceDic setObject:nodeId forKey:@"nodeId"];
        [deviceDic setObject:@1 forKey:@"endPoint"];
        [deviceDic setObject:connected forKey:@"isConnected"];
        [deviceDic setObject:[contactDeviceList[index2] valueForKey:@"title"] forKey:@"title"];

        [deviceDic setObject:[NSString stringWithFormat:@"%@", @"false"] forKey:@"isBinded"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceType"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceName"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToNodeId"];

        [contactDeviceList replaceObjectAtIndex:index2 withObject:deviceDic];
    }
    [[NSUserDefaults standardUserDefaults] setObject:contactDeviceList forKey:@"saved_list"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"deviceListTemp:- %@",contactDeviceList);
    [SVProgressHUD dismiss];
    if([connected isEqualToString:@"0"]){
        [self showAlertPopup:@"Device is offline, Please check the device connectivity."];
    }else{
        [self readContactSenserValue];
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
