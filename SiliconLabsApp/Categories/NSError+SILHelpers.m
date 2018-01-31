//
//  NSError+SILHelpers.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/22/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "NSError+SILHelpers.h"
#import "NSDictionary+SILErrorCode.h"

NSString * const SILHelpersErrorDomain = @"com.silabs.SilconLabsApp.ErrorDomain";

@implementation NSError (SILHelpers)

+ (instancetype)sil_errorWithCode:(SILErrorCode)code userInfo:(NSDictionary *)dict {
    return [NSError errorWithDomain:SILHelpersErrorDomain code:code userInfo:dict];
}

+ (instancetype)sil_errorWithCode:(SILErrorCode)code underlyingError:(NSError *)underlyingError {
    NSDictionary *userInfo = [NSDictionary userInfoDictionaryForErrorCode:code underlyingError:underlyingError];
    return [NSError sil_errorWithCode:code userInfo:userInfo];
}

@end
