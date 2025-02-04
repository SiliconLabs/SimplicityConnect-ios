//
//  SILBluetoothBrowser+Constants.m
//  BlueGecko
//
//  Created by Kamil Czajka on 09/03/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILBluetoothBrowser+Constants.h"

NSString * const EmptyText = @"";
float const StarterDBMValue = -100.0f;
CGFloat const CollapsedViewHeight = 0;
NSInteger const NoDeviceFoundIndex = -1;
const float AnimationExpandableControllerTime = 0.4;
const float AnimationExpandableControllerDelay = 0.0;
NSInteger DefaultDBMValue = -100;
NSInteger DefaultDBMMaxValue = -0;
NSString * const CommaAndSpaceText = @", ";
NSString * const QuoteText = @"\"";
NSString * const RSSITitle = @"RSSI > ";
NSString * const AppendingDBM = @" dBm";
NSString * const AppendingMS = @" ms";
NSString * const BeaconTypeTitle = @" + Beacon type ";
NSString * const SearchByDeviceNameTitle = @" + Name ";
NSString * const SearchByPacketContent = @" + Packet content ";
NSString * const OnlyFavouritesTitle = @" + Only favourites";
NSString * const OnlyConnectableTitle = @" + Only connectable";
NSString * const ShareLogsTitle = @"Simplicity Connect Logs\n";
NSString * const UnknownCharacteristicName = @"Unknown Characteristic";
char * const BackspaceString = "\b";
int const BackspaceASCIIValue = -8;
NSString * const DefaultDeviceName = @"N/A";
CGFloat CornerRadiusForButtons = 4.0;
CGFloat CornerRadiusStandardValue = 8.0;
NSString * const CannotWriteEmptyTextToCharacteristic = @"You cannot send an empty value to characteristic";
NSString * const FillAllMandatoryFields = @"Please fill all mandatory fields";
CGFloat LastFooterHeight = 40.0;
NSString* const TitleForScanningButtonDuringScanning = @"Stop Scanning";
NSString* const TitleForScanningButtonWhenIsNotScanning = @"Start Scanning";
const float TABLE_FRESH_INTERVAL = 1.0f;
NSString * const ActiveScanningText = @"Looking for nearby devices...";
NSString * const DisabledScanningText = @"No devices found";
