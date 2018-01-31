//
//  NSError+SILHelpers.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/22/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const SILHelpersErrorDomain;

typedef NS_ENUM(NSInteger, SILErrorCode) {
    SILErrorCodeUnknown,

    SILErrorCodeInvalidDataFormat,
    SILErrorCodePeripheralConnectionTimeout,
    SILErrorCodeOTADisconnectedFromPeripheral,
    SILErrorCodeOTAFailedToConnectToPeripheral,
    SILErrorCodeOTAFailedToFindOTAService,
    SILErrorCodeOTADiscoveredServicesError,
    SILErrorCodeOTAFailedToFindOTADataCharacteristic,
    SILErrorCodeOTADiscoveredCharacteristicsError,
    SILErrorCodeOTAFailedToWriteToCharacteristicError,
    SILErrorCodeOTAFailedToReadFile
};

@interface NSError (SILHelpers)

+ (instancetype)sil_errorWithCode:(SILErrorCode)code userInfo:(NSDictionary *)dict;

/**
 This method will return an error with a user dictionary configured for the supplied error code. 
 */
+ (instancetype)sil_errorWithCode:(SILErrorCode)code underlyingError:(NSError *)underlyingError;
@end
