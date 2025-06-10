//
//  SILLightSwitchTableViewCell.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 19/02/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

#import "SILLightSwitchTableViewCell.h"

@implementation SILLightSwitchTableViewCell
NSString * selectedDeviceData;
NSMutableDictionary *deviceDict;

- (void)awakeFromNib {
    [super awakeFromNib];
    //    self.deviceBGView.layer.cornerRadius = 14;
    self.deviceIconImage.tintColor = UIColor.sil_regularBlueColor;
    //[self.deviceNameLabel setHidden: TRUE];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setupCell:(NSDictionary *) deviceInfo {
    deviceDict = [[NSMutableDictionary alloc] init];
    deviceDict = [deviceInfo mutableCopy];
    selectedDeviceData = [NSString stringWithFormat:@"%@",[deviceInfo valueForKey:@"deviceType"]];
    NSString *connectedDevice = [deviceInfo valueForKey:@"isConnected"];
        
    NSString *deviceType = [NSString stringWithFormat:@"%@",[deviceDict valueForKey:@"deviceType"]];
        
    if ([deviceType isEqualToString:DimmingLight] || [deviceType isEqualToString:EnhancedColorLight] || [deviceType isEqualToString:OnOffLight] || [deviceType isEqualToString:TemperatureColorLight]) {
        self.deviceNameLabel.text = [NSString stringWithFormat:@"%@",[deviceInfo valueForKey:@"title"]];
    }
    
    if ([connectedDevice isEqual:@"1"]){
        self.deviceNameLabel.tintColor = UIColor.sil_regularBlueColor;
        self.deviceIconImage.tintColor = UIColor.sil_yellowColor;
    }else{
        self.deviceNameLabel.tintColor = UIColor.sil_lineGreyColor;
        self.deviceIconImage.tintColor = UIColor.sil_boulderColor;
    }
}

@end
