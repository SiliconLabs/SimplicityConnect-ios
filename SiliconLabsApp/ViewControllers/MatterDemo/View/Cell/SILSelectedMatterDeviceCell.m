//
//  SILSelectedMatterDeviceCell.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 25/09/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

#import "SILSelectedMatterDeviceCell.h"
#include "CHIPUIViewUtils.h"

@implementation SILSelectedMatterDeviceCell

NSString * selectedDevice;
NSMutableDictionary *deviceDic;

- (void)awakeFromNib {
    [super awakeFromNib];
    self.deviceBGView.layer.cornerRadius = 14;
}

- (void) setCell:(NSDictionary *) device {
    NSLog(@"deviceList %@", [device valueForKey:@"deviceType"]);
    deviceDic = [[NSMutableDictionary alloc] init];
    deviceDic = [device mutableCopy];
    selectedDevice = [NSString stringWithFormat:@"%@",[device valueForKey:@"deviceType"]];
    NSString *connectedDevice = [device valueForKey:@"isConnected"];
    
    NSString * deviceName;
    NSString * imgName;
    
    NSString *deviceType = [NSString stringWithFormat:@"%@",[deviceDic valueForKey:@"deviceType"]];
    
    if ([deviceType isEqualToString:@"514"]) {
        imgName = @"windowClose_icon";
    }else if ([deviceType isEqualToString:@"10"]){
        imgName = @"door_icon";
    }else if ([deviceType isEqualToString:DimmingLight] || [deviceType isEqualToString:EnhancedColorLight] || [deviceType isEqualToString:OnOffLight] || [deviceType isEqualToString:TemperatureColorLight]) { // 269 // 257 = before and 257 with wifi.
        imgName = @"light_icon";
    }else if ([deviceType isEqualToString:@"769"]){
        imgName = @"Temperature_Sensor_icon";
    }else if ([deviceType isEqualToString:@"267"]){
        imgName = @"plugBord_icon";
    }else if ([deviceType isEqualToString:@"770"]){
        imgName = @"temp_icon";
    }else if ([deviceType isEqualToString:@"263"]){
        imgName = @"OccupancySensor_icon";
    }else if ([deviceType isEqualToString:@"21"]){
        imgName = @"contactSensor_icon";
    }else if ([deviceType isEqualToString:@"259"]){
        imgName = @"switchOn_icon";
    } else if ([deviceType isEqualToString:Dishwasher]) {
        imgName = @"dishwasher_icon";
    } else if ([deviceType isEqualToString:AirQuality]) {
        imgName = @"airQuality_icon";
    }
    //_selectedMatterDeviceTitleLabel.text = deviceName;
    _selectedMatterDeviceTitleLabel.text = [NSString stringWithFormat:@"%@",[device valueForKey:@"title"]];
    _selectedMatterImage.image = [UIImage imageNamed:imgName];
    _uuidLabel.text = [NSString stringWithFormat:@"%@",[deviceDic valueForKey:@"endPoint"]];
    
    if ([connectedDevice isEqual:@"1"]){
        _deviceBGView.backgroundColor = UIColor.sil_bgWhiteColor;
        _selectedMatterDeviceTitleLabel.textColor = UIColor.blackColor;
        _selectedMatterImage.tintColor = UIColor.sil_regularBlueColor;
        _uuidLabel.textColor = UIColor.blackColor;
        _inactiveLbl.hidden = true;
    }else{
        _deviceBGView.backgroundColor = UIColor.sil_silverColor;
        _selectedMatterDeviceTitleLabel.textColor = UIColor.sil_boulderColor;
        _selectedMatterImage.tintColor = UIColor.sil_boulderColor;
        _uuidLabel.textColor = UIColor.sil_boulderColor;
        _inactiveLbl.hidden = true;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
