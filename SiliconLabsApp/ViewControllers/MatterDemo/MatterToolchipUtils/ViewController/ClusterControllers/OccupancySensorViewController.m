//
//  OccupancySensorViewController.m
//  BlueGecko
//
//  Created by SovanDas Maity on 16/10/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

#import "OccupancySensorViewController.h"
#import "CHIPUIViewUtils.h"
#import "DefaultsUtils.h"
#import "DeviceSelector.h"
#import <Matter/Matter.h>
@interface OccupancySensorViewController ()

@end
static OccupancySensorViewController * _Nullable oCurrentController = nil;

@implementation OccupancySensorViewController
@synthesize  nodeId, endPoint;
NSMutableArray * occupancyDeviceList;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    oCurrentController = self;
    occupancyDeviceList = [[NSMutableArray alloc] init];
    occupancyDeviceList = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    _occupancyImg.image = [UIImage imageNamed:@"OccupencySensor_iconOff"];
    _deviceCurrentStatusLabel.hidden = YES;
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear: animated];
    [self readDevice];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSDictionary* userInfo = @{@"controller": @"OccupancySensorViewController"};
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"controllerNotification"
     object:self userInfo:userInfo];
}

+ (nullable OccupancySensorViewController *)currentController {
    return oCurrentController;
}

-(void)readOccupancySensor {
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
                    if ([report.path.cluster isEqualToNumber:@(MTRClusterOccupancySensingID)] &&
                        [report.path.attribute
                         isEqualToNumber:@(MTRClusterOccupancySensingAttributeOccupancyID)]) {
                        NSLog(@"%@",report.path.cluster);
                        NSLog(@"%@",report.path.attribute);
                        if (report.error != nil) {
                            //MTRClusterOccupancySensingID
                            //MTRClusterOccupancySensingAttributeOccupancyID
                            //MTRAttributeIDTypeClusterOccupancySensingAttributeOccupancyID
                            NSLog(@"Error reading temperature: %@", report.error);
                        } else {
                            NSLog(@"%d",((NSNumber *) report.value).shortValue);
                            //temperatureLbl
                            __auto_type controller = [OccupancySensorViewController currentController];
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
- (void)updateTempInUI:(int)newTemp
{
    //    _selectedMatterImage.tintColor = UIColor.sil_regularBlueColor;
    NSString *myString = [@(newTemp) stringValue];
    if ([myString isEqualToString:@"1"]){
        _occupancyImg.image = [UIImage imageNamed:@"OccupencySensor_iconOn"];
    }else{
        _occupancyImg.image = [UIImage imageNamed:@"OccupencySensor_iconOff"];
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
    NSUInteger index2 = [occupancyDeviceList indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        BOOL found = [[item objectForKey:@"nodeId"] intValue] == node_id.intValue;
        return found;
    }];

    if([occupancyDeviceList count] > 0){
        NSNumber *nodeId = [occupancyDeviceList[index2] valueForKey:@"nodeId"];
        NSString *deviceType = [occupancyDeviceList[index2] valueForKey:@"deviceType"];
        
        NSMutableDictionary * deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:deviceType forKey:@"deviceType"];
        [deviceDic setObject:nodeId forKey:@"nodeId"];
        [deviceDic setObject:@1 forKey:@"endPoint"];
        [deviceDic setObject:connected forKey:@"isConnected"];
        [deviceDic setObject:[occupancyDeviceList[index2] valueForKey:@"title"] forKey:@"title"];

        [deviceDic setObject:[NSString stringWithFormat:@"%@", @"false"] forKey:@"isBinded"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceType"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceName"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToNodeId"];

        [occupancyDeviceList replaceObjectAtIndex:index2 withObject:deviceDic];
    }
    [[NSUserDefaults standardUserDefaults] setObject:occupancyDeviceList forKey:@"saved_list"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"deviceListTemp:- %@",occupancyDeviceList);
    [SVProgressHUD dismiss];
    if([connected isEqualToString:@"0"]){
        [self showAlertPopup:@"Device is offline, Please check the device connectivity."];
    }else{
        [self readOccupancySensor];
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
