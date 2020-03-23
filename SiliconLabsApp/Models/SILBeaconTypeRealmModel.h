//
//  SILBeaconTypeRealmModel.h
//  SiliconLabsApp
//
//  Created by Kamil Czajka on 19/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#ifndef SILBeaconTypeRealmModel_h
#define SILBeaconTypeRealmModel_h

#import <Realm/Realm.h>

@interface SILBeaconTypeRealmModel : RLMObject

@property NSString* beaconName;
@property BOOL isSelected;

- (instancetype)initWithName:(NSString*)beaconName andIsSelected:(BOOL)isSelected;

@end

#endif /* SILBeaconTypeRealmModel_h */
