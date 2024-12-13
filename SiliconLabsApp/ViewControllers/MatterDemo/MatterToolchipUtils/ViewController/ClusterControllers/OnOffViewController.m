
#import "OnOffViewController.h"
#import "CHIPUIViewUtils.h"
#import "DefaultsUtils.h"
#import "DeviceSelector.h"
#import <Matter/Matter.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface OnOffViewController ()
@property (nonatomic, strong) DeviceSelector * deviceSelector;

@end

@implementation OnOffViewController {
    
}
@synthesize  nodeId, endPoint;
NSMutableArray * lightDeviceList;
MTRBaseClusterOnOff * onOffLight;
MTRSubscribeParams * subParamLight;

// MARK: UIViewController methods

- (void)viewDidLoad {
    [super viewDidLoad];
    lightDeviceList = [[NSMutableArray alloc] init];
    lightDeviceList = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    subParamLight = [[MTRSubscribeParams alloc] initWithMinInterval:@2 maxInterval:@5];
    [self readDevice];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupUIElements];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSDictionary* userInfo = @{@"controller": @"OnOffViewController"};
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
    _toggleButton.layer.cornerRadius = 5;
    _toggleButton.clipsToBounds = YES;
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
    
    if (@available(iOS 16.1, *)) {
        if (@available(iOS 16.1, *)) {
            [onOffLight onWithCompletionHandler:^(NSError * error) {
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
}

- (IBAction)offButtonTapped:(id)sender
{
    if (@available(iOS 16.1, *)) {
        [onOffLight offWithCompletionHandler:^(NSError * error) {
            NSString * resultString = (error != nil)
            ? [NSString stringWithFormat:@"An error occurred: 0x%02lx", error.code]
            : @"Off";
            [self updateResult:resultString];
        }];
    } else {
        // Fallback on earlier versions
    }
}

- (IBAction)toggleButton:(id)sender {
    
    if (@available(iOS 16.1, *)) {
        if (@available(iOS 16.1, *)) {
            [onOffLight toggleWithCompletion:^(NSError * _Nullable error) {
                [self readDeviceStateAfterToggle];
            }];
        } else {
            // Fallback on earlier versions
        }
    } else {
        // Fallback on earlier versions
    }
    

}

-(void) readCurrentStateFromDevice {
    
    NSInteger endpoint = 1;
   uint64_t _devId = nodeId.intValue;
   if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
       if (chipDevice) {
           [onOffLight subscribeAttributeOnOffWithParams:subParamLight subscriptionEstablished:^{
           } reportHandler:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                   if([value isEqual:@1]){
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

- (void)readDeviceStateAfterToggle {
    NSInteger endpoint = 1;
    uint64_t _devId = nodeId.intValue;
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            // Start: - Light
//            MTRBaseClusterOnOff * onOff = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
//                                                                             endpoint:endpoint
//                                                                                queue:dispatch_get_main_queue()];
            [onOffLight readAttributeOnOffWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                NSLog(@"chipDevice %@", value);
                
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

// Update image Status
- (void) updateImageStatus: (BOOL) status {
    if (status == TRUE) {
        _clusterImage.tintColor = UIColor.sil_yellowColor;
    } else {
        _clusterImage.tintColor = UIColor.sil_boulderColor;
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
            onOffLight = [[MTRBaseClusterOnOff alloc] initWithDevice:chipDevice
                                                                             endpoint:endpoint
                                                                                queue:dispatch_get_main_queue()];
            [onOffLight readAttributeOnOffWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
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
    NSUInteger index2 = [lightDeviceList indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        BOOL found = [[item objectForKey:@"nodeId"] intValue] == node_id.intValue;
        return found;
    }];
    //NSLog(@" index2 ======== %d\n", index2);
    if([lightDeviceList count] > 0){
        NSNumber *nodeId = [lightDeviceList[index2] valueForKey:@"nodeId"];
        NSString *deviceType = [lightDeviceList[index2] valueForKey:@"deviceType"];
        
        NSMutableDictionary * deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:deviceType forKey:@"deviceType"];
        [deviceDic setObject:nodeId forKey:@"nodeId"];
        [deviceDic setObject:@1 forKey:@"endPoint"];
        [deviceDic setObject:connected forKey:@"isConnected"];
        [deviceDic setObject:[lightDeviceList[index2] valueForKey:@"title"] forKey:@"title"];
        [lightDeviceList replaceObjectAtIndex:index2 withObject:deviceDic];
    }
    [[NSUserDefaults standardUserDefaults] setObject:lightDeviceList forKey:@"saved_list"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"deviceListTemp:- %@",lightDeviceList);
    [SVProgressHUD dismiss];
    if([connected isEqualToString:@"0"]){
        [self showAlertPopup:@"Device is offline, Please check the device connectivity."];
    }else{
        //[self readCurrentStateFromDevice];
        NSTimeInterval delayInSeconds = 5.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
          NSLog(@"Do some work");
           [self readCurrentStateFromDevice];
        });
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
