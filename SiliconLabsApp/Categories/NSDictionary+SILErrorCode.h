//
//  NSDictionary+SILErrorCode.h
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/12/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSError+SILHelpers.h"

@interface NSDictionary (SILErrorCode)

+ (NSDictionary *)userInfoDictionaryForErrorCode:(SILErrorCode)errorCode underlyingError:(NSError *)underlyingError;

@end
