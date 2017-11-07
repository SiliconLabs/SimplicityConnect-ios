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

NSString * const SILCharacteristicNumberAlertLevel = @"2A06";
NSString * const SILCharacteristicNumberTXPowerLevel = @"2A07";
NSString * const SILCharacteristicNumberTemperatureMeasurement = @"2A1C";
NSString * const SILCharacteristicNumberHeartRateMeasurement = @"2A37";
NSString * const SILCharacteristicNumberBodySensorLocation = @"2A38";

NSInteger const SILConstantsStrongSignalThreshold = -50;
NSInteger const SILConstantsMediumSignalThreshold = -80;

NSInteger const SILConstantsTxPowerDefault = -40;
