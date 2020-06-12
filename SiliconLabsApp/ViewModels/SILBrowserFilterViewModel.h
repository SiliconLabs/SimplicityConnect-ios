//
//  SILBrowserFilterViewModel.h
//  BlueGecko
//
//  Created by Kamil Czajka on 17/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILBrowserBeaconType.h"
#import "SILBrowserSavedSearches.h"

NS_ASSUME_NONNULL_BEGIN

@interface SILBrowserFilterViewModel : NSObject

@property (strong, nonatomic, readwrite) NSString *searchByDeviceName;
@property (nonatomic, readwrite) NSInteger dBmValue;
@property (nonatomic, readwrite) BOOL isBeaconTypeExpanded;
@property (nonatomic, readwrite) BOOL isFavouriteFilterSet;
@property (nonatomic, readwrite) BOOL isConnectableFilterSet;
@property (nonatomic, readwrite) BOOL isSavedSearchesExpaned;
@property (nonatomic, readwrite) CGFloat beaconTypeTableViewHeight;
@property (nonatomic, readwrite) CGFloat savedSearchesTableViewHeight;
@property (nonatomic, readwrite) NSMutableArray<SILBrowserBeaconType*>* beaconTypes;
@property (nonatomic, readwrite) NSMutableArray<SILBrowserSavedSearches*>* savedSearches;
@property (nonatomic, readwrite) BOOL isActiveFilterFromSavedSearches;

+ (instancetype)sharedInstance;
- (void)saveCurrentFilterDataToSavedSearches;
- (void)clearViewModelData;
- (NSString*)getStringRepresentationForObjectAtIndex:(NSUInteger)index;
- (void)updateSavedSearches:(NSInteger)indexPath;
- (BOOL)isFilterActive;

@end

NS_ASSUME_NONNULL_END

