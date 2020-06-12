//
//  SILSavedSearchesRealmModel.h
//  SiliconLabsApp
//
//  Created by Kamil Czajka on 19/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#ifndef SILSavedSearchesRealmModel_h
#define SILSavedSearchesRealmModel_h

#import <Realm/Realm.h>
#import "SILBrowserBeaconType.h"
#import "SILBeaconTypeRealmModel.h"

RLM_ARRAY_TYPE(SILBeaconTypeRealmModel)

@interface SILSavedSearchesRealmModel : RLMObject

@property NSString* searchByDeviceName;
@property NSInteger dBmValue;
@property RLMArray<SILBeaconTypeRealmModel *><SILBeaconTypeRealmModel>* beaconTypes;
@property BOOL isFavouriteSetFilter;
@property BOOL isConnectableSetFilter;

- (instancetype)initWithSearchByDeviceNameText:(NSString*)searchByDeviceNameText dBmValue:(NSInteger)dBmValue beaconTypes:(RLMArray<SILBeaconTypeRealmModel*>*)beaconTypes isFavourite:(BOOL)isFavourite andIsConnectable:(BOOL)isConnectable;

@end

#endif /* SILSavedSearchesRealmModel_h */
