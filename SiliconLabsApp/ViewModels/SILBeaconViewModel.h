//
//  SILBeaconViewModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/18/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILBeacon.h"
#import "UIImage+SILImages.h"
@class SILBeacon, SILDoubleKeyDictionaryPair;

// "ABSTRACT" BASE CLASS //
@interface SILBeaconViewModel : NSObject
@property (strong, nonatomic, readonly) SILBeacon *beacon;
@property (strong, nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSString *imageName;
@property (strong, nonatomic, readonly) UIImage *image;
@property (strong, nonatomic, readonly) NSString *type;
@property (strong, nonatomic, readonly) NSNumber *rssi;
@property (strong, nonatomic, readonly) NSNumber *tx;
@property (strong, nonatomic, readonly) SILDoubleKeyDictionaryPair *beaconDetails;

- (instancetype)initWithBeacon:(SILBeacon *)beacon;

@end
