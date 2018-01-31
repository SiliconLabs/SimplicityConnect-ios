//
//  NSDictionary+SILErrorCode.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/12/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "NSDictionary+SILErrorCode.h"

static NSString * const kSILOTAFailedToConnectToPeripheralErrorText = @"Failed to connect to peripheral";
static NSString * const kSILOTAFailedToFindOTAServiceErrorText = @"Failed to find OTA service";
static NSString * const kSILOTAFailedToFindOTADataCharacteristicErrorText = @"Failed to find OTA data characteristic";
static NSString * const kSILErrorCodeOTADisconnectedFromPeripheralErrorText = @"Unexpectedly disconnected from peripheral";
static NSString * const kSILErrorCodeOTAFailedToReadFileErrorText = @"Failed to read firmware file";

static NSString * const kSILDefaultRecoverySuggestion = @"Please try again";
static NSString * const kSILOTAFailedToConnectToOrDiconnectedFromPeripheralRecoverySuggestion = @"Please reconnect and try again";

@implementation NSDictionary (SILErrorCode)

+ (NSDictionary *)userInfoDictionaryForErrorCode:(SILErrorCode)errorCode underlyingError:(NSError *)underlyingError {
    NSDictionary *userInfo;
    switch (errorCode) {
        case SILErrorCodeUnknown:
        case SILErrorCodeInvalidDataFormat:
        case SILErrorCodePeripheralConnectionTimeout:
            break;
        case SILErrorCodeOTADisconnectedFromPeripheral:
            userInfo = [NSDictionary userInfoDictionaryForLocalizedDescription:kSILErrorCodeOTADisconnectedFromPeripheralErrorText
                                                   localizedRecoverySuggestion:kSILOTAFailedToConnectToOrDiconnectedFromPeripheralRecoverySuggestion];
            break;
        case SILErrorCodeOTAFailedToConnectToPeripheral:
            userInfo = [NSDictionary userInfoDictionaryForLocalizedDescription:kSILOTAFailedToConnectToPeripheralErrorText
                                                   localizedRecoverySuggestion:kSILOTAFailedToConnectToOrDiconnectedFromPeripheralRecoverySuggestion];
            break;
        case SILErrorCodeOTAFailedToFindOTAService:
            userInfo = [NSDictionary userInfoDictionaryForLocalizedDescription:kSILOTAFailedToFindOTAServiceErrorText
                                                   localizedRecoverySuggestion:kSILDefaultRecoverySuggestion];
            break;
        case SILErrorCodeOTADiscoveredServicesError:
            userInfo = [NSDictionary userInfoDictionaryForUnderlyringError:underlyingError];
            break;
        case SILErrorCodeOTAFailedToFindOTADataCharacteristic:
            userInfo = [NSDictionary userInfoDictionaryForLocalizedDescription:kSILOTAFailedToFindOTADataCharacteristicErrorText
                                                   localizedRecoverySuggestion:kSILDefaultRecoverySuggestion];
            break;
        case SILErrorCodeOTADiscoveredCharacteristicsError:
            userInfo = [NSDictionary userInfoDictionaryForUnderlyringError:underlyingError];
            break;
        case SILErrorCodeOTAFailedToWriteToCharacteristicError:
            userInfo = [NSDictionary userInfoDictionaryForUnderlyringError:underlyingError];
            break;
        case SILErrorCodeOTAFailedToReadFile:
            userInfo = [NSDictionary userInfoDictionaryForLocalizedDescription:kSILErrorCodeOTAFailedToReadFileErrorText
                                                   localizedRecoverySuggestion:kSILDefaultRecoverySuggestion];
        default:
            break;
    }
    return userInfo;
}

+ (NSDictionary *)userInfoDictionaryForLocalizedDescription:(NSString *)localizedDescription
                                localizedRecoverySuggestion:(NSString *)localizedRecoverySuggestion {
    return @{
             NSLocalizedDescriptionKey : localizedDescription,
             NSLocalizedRecoverySuggestionErrorKey : localizedRecoverySuggestion
             };
}

+ (NSDictionary *)userInfoDictionaryForUnderlyringError:(NSError *)error {
    return @{
             NSUnderlyingErrorKey : error,
             };
}

@end
