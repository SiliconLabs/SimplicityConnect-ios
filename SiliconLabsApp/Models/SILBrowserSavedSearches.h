//
//  SILBrowserSavedSarches.h
//  SiliconLabsApp
//
//  Created by Kamil Czajka on 18/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#ifndef SILBrowserSavedSarches_h
#define SILBrowserSavedSarches_h

#import "SILBrowserBeaconType.h"

@interface SILBrowserSavedSearches : NSObject

@property (strong, nonatomic, readonly) NSString *searchByDeviceNameText;
@property (nonatomic, readonly) NSInteger dBmValue;
@property (nonatomic, readonly) NSInteger dBmMaxValue;
@property (strong, nonatomic, readonly) NSArray<SILBrowserBeaconType*>* beaconTypes;
@property (nonatomic, readonly) BOOL isFavourite;
@property (nonatomic, readonly) BOOL isConnectable;
@property (nonatomic, readonly) BOOL isSelected;

- (instancetype)initWithSearchByDeviceNameText:(NSString*)searchByDeviceNameText dBmValue:(NSInteger)dBmValue beaconTypes:(NSArray<SILBrowserBeaconType*>*)beaconTypes isFavourite:(BOOL)isFavourite isConnectable:(BOOL)isConnectable andIsSelected:(BOOL)isSelected;
- (void)setSelection:(BOOL)isSelected;

@end


#endif /* SILBrowserSavedSarches_h */
