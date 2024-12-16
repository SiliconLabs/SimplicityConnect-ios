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
        //deviceName = [NSMutableString stringWithFormat:@"Window Cover - %@", [deviceDic valueForKey:@"nodeId"]];
        imgName = @"windowClose_icon";
    }else if ([deviceType isEqualToString:@"10"]){
        //deviceName = [NSMutableString stringWithFormat:@"Door Lock - %@", [deviceDic valueForKey:@"nodeId"]];
        imgName = @"door_icon";
    }else if ([deviceType isEqualToString:DimmingLight] || [deviceType isEqualToString:EnhancedColorLight] || [deviceType isEqualToString:OnOffLight] || [deviceType isEqualToString:TemperatureColorLight]) { // 269 // 257 = before and 257 with wifi.
        //deviceName = [NSMutableString stringWithFormat:@"Light - %@", [deviceDic valueForKey:@"nodeId"]];
        imgName = @"light_icon";
    }else if ([deviceType isEqualToString:@"769"]){
        //deviceName = [NSMutableString stringWithFormat:@"Thermostat - %@", [deviceDic valueForKey:@"nodeId"]];
        imgName = @"Temperature_Sensor_icon";
    }else if ([deviceType isEqualToString:@"267"]){
        //deviceName = [NSMutableString stringWithFormat:@"Plug - %@", [deviceDic valueForKey:@"nodeId"]];
        imgName = @"plugBord_icon";
    }else if ([deviceType isEqualToString:@"770"]){
        //Temperature Sensor
        //deviceName = [NSMutableString stringWithFormat:@"Temperature Sensor - %@", [deviceDic valueForKey:@"nodeId"]];
        imgName = @"temp_icon";
    }else if ([deviceType isEqualToString:@"263"]){
        //Occupancy Sensor
        //deviceName = [NSMutableString stringWithFormat:@"Occupancy Sensor - %@", [deviceDic valueForKey:@"nodeId"]];
        imgName = @"OccupancySensor_icon";
    }else if ([deviceType isEqualToString:@"21"]){
        //Contact Sensor
        //deviceName = [NSMutableString stringWithFormat:@"Contact Sensor - %@", [deviceDic valueForKey:@"nodeId"]];
        imgName = @"contactSensor_icon";
    }else if ([deviceType isEqualToString:@"259"]){
        //Switch
        //deviceName = [NSMutableString stringWithFormat:@"Switch - %@", [deviceDic valueForKey:@"nodeId"]];
        imgName = @"switchOn_icon";
    } else if ([deviceType isEqualToString:Dishwasher]) {
        imgName = @"dishwasher_icon";
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
