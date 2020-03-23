//
//  SILBrowserSavedSearches.m
//  BlueGecko
//
//  Created by Kamil Czajka on 18/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILBrowserSavedSearches.h"

@interface SILBrowserSavedSearches ()

@property (strong, nonatomic, readwrite) NSString *searchByDeviceNameText;
@property (strong, nonatomic, readwrite) NSString *searchByRawAdvetisingDataText;
@property (nonatomic, readwrite) NSInteger dBmValue;
@property (strong, nonatomic, readwrite) NSArray<SILBrowserBeaconType*>* beaconTypes;
@property (nonatomic, readwrite) BOOL isFavourite;
@property (nonatomic, readwrite) BOOL isConnectable;
@property (nonatomic, readwrite) BOOL isSelected;

@end

@implementation SILBrowserSavedSearches : NSObject

- (instancetype)initWithSearchByDeviceNameText:(NSString*)searchByDeviceNameText searchByRawAdveritisingDataText:(NSString*)searchByRawAdvetisingDataText dBmValue:(NSInteger)dBmValue beaconTypes:(NSArray<SILBrowserBeaconType*>*)beaconTypes isFavourite:(BOOL)isFavourite isConnectable:(BOOL)isConnectable andIsSelected:(BOOL)isSelected {
    self = [super init];
    if (self) {
        self.searchByDeviceNameText = searchByDeviceNameText;
        self.searchByRawAdvetisingDataText = searchByRawAdvetisingDataText;
        self.dBmValue = dBmValue;
        self.beaconTypes = beaconTypes;
        self.isFavourite = isFavourite;
        self.isConnectable = isConnectable;
        self.isSelected = isSelected;
    }
    
    return self;
}

- (void)setSelection:(BOOL)isSelected {
    self.isSelected = isSelected;
}

@end
