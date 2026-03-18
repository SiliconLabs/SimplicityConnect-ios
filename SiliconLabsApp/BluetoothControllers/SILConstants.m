//
//  SILConstants.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/4/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILConstants.h"

NSString * const SILServiceNumberImmediateAlert = @"1802";
NSString * const SILServiceNumberLinkLoss = @"1803";
NSString * const SILServiceNumberTXPower = @"1804";
NSString * const SILServiceNumberHealthThermometer = @"1809";
NSString * const SILServiceNumberHeartRate = @"180D";
NSString * const SILServiceNumberHumanInterfaceDevice = @"1812";
NSString * const SILServiceNumberConnectedDeviceConnect = @"62792313-ADF2-4FC9-974D-FAB9DDF2622C";
NSString * const SILServiceNumberConnectedDeviceProprietary = @"63f596e4-b583-4078-bfc3-b04225378713";
NSString * const SILServiceNumberConnectedDeviceThread = @"dd1c077d-d306-4b30-846a-4f55cc35767a";
NSString * const SILServiceNumberConnectedDeviceZigbee = @"BAE55B96-7D19-458D-970C-50613D801BC9";
NSString * const SILServiceNumberRangeTest = @"530AA649-17E6-4D62-9F20-9E393B177E63";
NSString * const SILServiceNumberESLServiceControl = @"35100001-4B1D-B16B-00B1-35018BADF00D";
//NSString * const SILServiceNumberConnectedDeviceSideWalk = @"9e8dea42-557b-4797-a890-90c5a93da1af";
NSString * const SILServiceNumberConnectedDeviceSideWalk = @"9E8DEA42-557B-4797-A890-90C5A93DA1AF"; //9E8DEA42-557B-4797-A890-90C5A93DA1AF

NSString * const SILServiceNumberConnectedDeviceAWSIoT = @"FD63";
NSString * const smartLockStateChangeCharacteristicUUID = @"1AA1";
NSString * const ssmartLockStateReadCharacteristicUUID = @"1CC1";


NSString * const SILCharacteristicNumberAlertLevel = @"2A06";
NSString * const SILCharacteristicNumberTXPowerLevel = @"2A07";
NSString * const SILCharacteristicNumberTemperatureMeasurement = @"2A1C";
NSString * const SILCharacteristicNumberTemperatureMeasurementType = @"2A1D";
NSString * const SILCharacteristicNumberHeartRateMeasurement = @"2A37";
NSString * const SILCharacteristicNumberBodySensorLocation = @"2A38";
NSString * const SILCharacteristicNumberDMPLightState = @"76E137AC-B15F-49D7-9C4C-E278E6492AD9";
NSString * const SILCharacteristicNumberDMPSwitchSource = @"2F16EE52-0BFD-4597-85D4-A5141FDBAE15";
NSString * const SILCharacteristicNumberDMPSourceAddress = @"82A1CB54-3921-4C9C-BA34-34F78BAB9A1B";

NSString * const SILDiscoveredPeripheralConnectableDevice = @"Connectable";
NSString * const SILDiscoveredPeripheralNonConnectableDevice = @"N-connectable";
NSString * const SILPeerRemovedPairingMessage = @"The peripheral can't be connected because of peripheral has removed pairing information. Please go to the Settings of your device and remove the pair with peripheral, then try to connect again.";

NSInteger const SILConstantsStrongSignalThreshold = -50;
NSInteger const SILConstantsMediumSignalThreshold = -80;

NSInteger const SILConstantsTxPowerDefault = -40;

NSInteger const SILLargeFontSizeIphones = 18;
NSInteger const SILLargeFontSizeIpads = 22;
NSInteger const SILMediumFontSizeIphones = 14;
NSInteger const SILMediumFontSizeIpads = 20;
NSInteger const SILSmallFontSizeIphones = 12;
NSInteger const SILSmallFontSizeIpads = 20;
NSInteger const SILNavigationBarTitleFontSize = 34;
NSInteger const SILGattConfiguratorNavigationBarTitleFontSize = 28;
NSInteger const SILScanningButtonTitleFontSize = 18;

CGFloat const SILCornerRadius = 20.0;
