//
//  SILBrowserFilterViewModel.m
//  BlueGecko
//
//  Created by Kamil Czajka on 17/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILBrowserFilterViewModel.h"
#import "SILBrowserBeaconType.h"
#import "SILSavedSearchesRealmModel.h"
#import "NSString+SILBrowserNotifications.h"
#import "SILBluetoothBrowser+Constants.h"
#import "SILBeacon.h"
#import <Realm/Realm.h>

@interface SILBrowserFilterViewModel ()

@property RLMRealm* defaultRealm;
@property RLMResults* savedSearchesRealm;

@end

@implementation SILBrowserFilterViewModel

#pragma mark - Initializers

+ (instancetype)sharedInstance {
    static SILBrowserFilterViewModel *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SILBrowserFilterViewModel alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setDefaultValues];
        [self fillBeaconTypesArray];
        [self addObservers];
        [self installRealmDatabase];
    }
    return self;
}

- (void)installRealmDatabase {
    _defaultRealm = [RLMRealm defaultRealm];
}

# pragma mark - Default Values

- (void)setDefaultValues {
    self.searchByDeviceName = EmptyText;
    self.dBmValue = DefaultDBMValue;
    self.dBmMaxValue = DefaultDBMMaxValue;
    self.isBeaconTypeExpanded = NO;
    self.isFavouriteFilterSet = NO;
    self.isConnectableFilterSet = NO;
    self.isSavedSearchesExpaned = NO;
    self.beaconTypeTableViewHeight = CollapsedViewHeight;
    self.savedSearchesTableViewHeight = CollapsedViewHeight;
    self.beaconTypes = [[NSMutableArray alloc] init];
    self.savedSearches = [[NSMutableArray alloc] init];
    self.isActiveFilterFromSavedSearches = NO;
    [self fillSavedSearches];
}

- (void)clearViewModelData {
    self.searchByDeviceName = EmptyText;
    self.dBmValue = DefaultDBMValue;
    self.dBmMaxValue = DefaultDBMMaxValue;
    self.isConnectableFilterSet = NO;
    self.isFavouriteFilterSet = NO;
    self.beaconTypes = [[NSMutableArray alloc] init];
    self.isActiveFilterFromSavedSearches = NO;
    [self fillBeaconTypesArray];
    [self postReloadFilterViewNotification];
    [self fillSavedSearches];
}

- (void)returnStateFrom:(SILBrowserSavedSearches*)savedSearch {
    self.searchByDeviceName = savedSearch.searchByDeviceNameText;
    self.dBmValue = savedSearch.dBmValue;
    self.dBmMaxValue = savedSearch.dBmMaxValue;
    self.isFavouriteFilterSet = savedSearch.isFavourite;
    self.isConnectableFilterSet = savedSearch.isConnectable;
    [self initNewBeaconTypes:savedSearch.beaconTypes];
}

# pragma mark - Beacon Types Array

- (void)fillBeaconTypesArray {
    SILBrowserBeaconType* unknown = [[SILBrowserBeaconType alloc] initWithName:SILBeaconUnspecified andSelection:NO];
    SILBrowserBeaconType* iBeacon = [[SILBrowserBeaconType alloc] initWithName:SILBeaconIBeacon andSelection:NO];
    SILBrowserBeaconType* altBeacon = [[SILBrowserBeaconType alloc] initWithName:SILBeaconAltBeacon andSelection:NO];
    SILBrowserBeaconType* eddystone = [[SILBrowserBeaconType alloc] initWithName:SILBeaconEddystone andSelection:NO];
    [_beaconTypes addObjectsFromArray:@[unknown, iBeacon, altBeacon, eddystone]];
}

- (void)initNewBeaconTypes:(NSArray<SILBrowserBeaconType*>*)oldBeaconTypes {
    SILBrowserBeaconType* unknown = [[SILBrowserBeaconType alloc] initWithName:SILBeaconUnspecified andSelection:NO];
    SILBrowserBeaconType* iBeacon = [[SILBrowserBeaconType alloc] initWithName:SILBeaconIBeacon andSelection:NO];
    SILBrowserBeaconType* altBeacon = [[SILBrowserBeaconType alloc] initWithName:SILBeaconAltBeacon andSelection:NO];
    SILBrowserBeaconType* eddystone = [[SILBrowserBeaconType alloc] initWithName:SILBeaconEddystone andSelection:NO];
   
    if( oldBeaconTypes[0].isSelected) {
        [unknown modifySelection];
    }
    if (oldBeaconTypes[1].isSelected) {
        [iBeacon modifySelection];
    }
    if (oldBeaconTypes[2].isSelected) {
        [altBeacon modifySelection];
    }
    if (oldBeaconTypes[3].isSelected) {
        [eddystone modifySelection];
    }
    
    _beaconTypes = [[NSMutableArray alloc] init];
    [_beaconTypes addObjectsFromArray:@[unknown, iBeacon, altBeacon, eddystone]];
}

# pragma mark - Observers

- (void)addObservers {
    [self addDeleteSavedSearchNotification];
}

- (void)addDeleteSavedSearchNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteSavedSearch:) name:SILNotificationDeleteSavedSearch object:nil];
}

- (void)postReloadSavedSearchesViewHeightNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationReloadSavedSearchesViewHeight object:self userInfo:nil];
}

- (void)postSavedSearchesTableViewNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationReloadSavedSearchesTableViewHeight object:self userInfo:nil];
}

- (void)postReloadFilterViewNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationReloadFilterView object:self userInfo:nil];
}

#pragma mark - Properties

- (void)setSavedSearchesTableViewHeight:(CGFloat)savedSearchesTableViewHeight {
    if (_savedSearchesTableViewHeight != savedSearchesTableViewHeight) {
        _savedSearchesTableViewHeight = savedSearchesTableViewHeight;
        [self postReloadSavedSearchesViewHeightNotification];
    }
}

- (void)setIsActiveFilterFromSavedSearches:(BOOL)isActiveFilterFromSavedSearches {
    if (_isActiveFilterFromSavedSearches != isActiveFilterFromSavedSearches) {
        _isActiveFilterFromSavedSearches = isActiveFilterFromSavedSearches;
        if (_isActiveFilterFromSavedSearches == NO) {
            [self updateSavedSearches:NoDeviceFoundIndex];
        }
    }
}

- (void)setSearchByDeviceName:(NSString *)searchByDeviceName {
    if (_searchByDeviceName != searchByDeviceName) {
        _searchByDeviceName = searchByDeviceName;
        [self changeStateOfIsActiveFilterFromSavedSearchesIfNeeded];
    }
}

- (void)setDBmValue:(NSInteger)dBmValue {
    if (_dBmValue != dBmValue) {
        _dBmValue = dBmValue;
        [self changeStateOfIsActiveFilterFromSavedSearchesIfNeeded];
    }
}

- (void)setIsFavouriteFilterSet:(BOOL)isFavouriteFilterSet {
    if (_isFavouriteFilterSet != isFavouriteFilterSet) {
        _isFavouriteFilterSet = isFavouriteFilterSet;
        [self changeStateOfIsActiveFilterFromSavedSearchesIfNeeded];
    }
}

- (void)setIsConnectableFilterSet:(BOOL)isConnectableFilterSet {
    if (_isConnectableFilterSet != isConnectableFilterSet) {
        _isConnectableFilterSet = isConnectableFilterSet;
        [self changeStateOfIsActiveFilterFromSavedSearchesIfNeeded];
    }
}

- (void)changeStateOfIsActiveFilterFromSavedSearchesIfNeeded {
    if (_isActiveFilterFromSavedSearches == YES) {
        _isActiveFilterFromSavedSearches = NO;
        [self updateSavedSearches:NoDeviceFoundIndex];
    }
}

#pragma mark - Saving Search

- (void)saveCurrentFilterDataToSavedSearches {
    SILBrowserSavedSearches* saveSearch = [[SILBrowserSavedSearches alloc] initWithSearchByDeviceNameText:_searchByDeviceName dBmValue:_dBmValue beaconTypes:_beaconTypes isFavourite:_isFavouriteFilterSet isConnectable:_isConnectableFilterSet andIsSelected:NO];
    if ([self isUniqueSavedSearches:saveSearch]) {
        [_savedSearches addObject:saveSearch];
        [self updateSavedSearches:[_savedSearches count] - 1];
        [self saveSearchInRealmDatabase:saveSearch];
        [self setIsActiveFilterFromSavedSearches:YES];
    }
    [self initNewBeaconTypes:_beaconTypes];
    [self postSavedSearchesTableViewNotification];
}

- (void)saveSearchInRealmDatabase:(SILBrowserSavedSearches*)savedSearch {
    SILSavedSearchesRealmModel* saveSearchRealm = [[SILSavedSearchesRealmModel alloc] init];
    saveSearchRealm.searchByDeviceName = savedSearch.searchByDeviceNameText;
 //   saveSearchRealm.searchByAdvertisingData = savedSearch.searchByRawAdvetisingDataText;
    saveSearchRealm.dBmValue = savedSearch.dBmValue;
    saveSearchRealm.isFavouriteSetFilter = savedSearch.isFavourite;
    saveSearchRealm.isConnectableSetFilter = savedSearch.isConnectable;
    for (SILBrowserBeaconType* beaconType in savedSearch.beaconTypes) {
        SILBeaconTypeRealmModel* beaconRealm = [[SILBeaconTypeRealmModel alloc] initWithName:beaconType.beaconName andIsSelected:beaconType.isSelected];
        [saveSearchRealm.beaconTypes addObject:beaconRealm];
    }
    [_defaultRealm transactionWithBlock:^{
       [_defaultRealm addObject:saveSearchRealm];
    }];
}


- (BOOL)isUniqueSavedSearches:(SILBrowserSavedSearches*)newSavedSearches {
    for (SILBrowserSavedSearches* savedSearches in _savedSearches) {
        if ([self isEqualTwoSavedSearches:savedSearches andSecond:newSavedSearches]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)isEqualTwoSavedSearches:(SILBrowserSavedSearches*)savedSearch andSecond:(SILBrowserSavedSearches*)savedSearch2 {
    if (![savedSearch.searchByDeviceNameText isEqualToString:savedSearch2.searchByDeviceNameText]) {
        return NO;
    }
    if (savedSearch.dBmValue != savedSearch2.dBmValue) {
        return NO;
    }
    if (savedSearch.isFavourite != savedSearch2.isFavourite) {
        return NO;
    }
    if (savedSearch.isConnectable != savedSearch2.isConnectable) {
        return NO;
    }
    for (int i = 0; i < [savedSearch.beaconTypes count]; i++) {
        if (savedSearch.beaconTypes[i].isSelected != savedSearch2.beaconTypes[i].isSelected) {
            return NO;
        }
    }
    return YES;
}

# pragma mark - Saved Searches

- (void)updateSavedSearches:(NSInteger)index {
    if (index != NoDeviceFoundIndex) {
        [self returnValuesFromSavedSearchesWithIndex:index];
    }
    
    [self updateSavedSearchesSelectionWithIndex:index];
}

- (void)returnValuesFromSavedSearchesWithIndex:(NSInteger)index {
    SILBrowserSavedSearches* currentSavedSearch = _savedSearches[index];
    [self returnStateFrom:currentSavedSearch];
    [self postReloadFilterViewNotification];
}

- (void)updateSavedSearchesSelectionWithIndex:(NSInteger)index {
    for (int i = 0; i < [_savedSearches count]; i++) {
        if (i != index) {
            [_savedSearches[i] setSelection:NO];
        } else {
            [_savedSearches[i] setSelection:YES];
        }
    }
    [self postSavedSearchesTableViewNotification];
}

- (void)deleteSavedSearch:(NSNotification*)notification {
    NSDictionary* userInfo = notification.userInfo;
    NSNumber* indexNumber = (NSNumber*)userInfo[SILNotificationKeyIndex];
    NSUInteger index = [indexNumber unsignedIntValue];
    [self deleteSavedSearchFromRealm:index];
    [self deleteSavedSearchFromViewModel:index];
    [self postSavedSearchesTableViewNotification];
}

- (void)deleteSavedSearchFromRealm:(NSUInteger)index {
    [_defaultRealm transactionWithBlock:^{
        [_defaultRealm deleteObject:_savedSearchesRealm[index]];
    }];
}

- (void)deleteSavedSearchFromViewModel:(NSUInteger)index {
    [_savedSearches removeObjectAtIndex:index];
}

- (void)fillSavedSearches {
    _savedSearchesRealm = [SILSavedSearchesRealmModel allObjects];
    
    for (SILSavedSearchesRealmModel* savedSearch in _savedSearchesRealm) {
        [_savedSearches addObject:[self getSavedSearchRealmObject:savedSearch]];
    }
}

- (SILBrowserSavedSearches*)getSavedSearchRealmObject:(SILSavedSearchesRealmModel*)savedSearchRealm {
    NSMutableArray<SILBrowserBeaconType*>* beaconTypes = [[NSMutableArray alloc] init];
    for (SILBeaconTypeRealmModel* savedSearchBeacon in savedSearchRealm.beaconTypes) {
        SILBrowserBeaconType* beacon = [[SILBrowserBeaconType alloc] initWithName:savedSearchBeacon.beaconName andSelection:savedSearchBeacon.isSelected];
        [beaconTypes addObject:beacon];
    }
    SILBrowserSavedSearches* browserSavedSearch = [[SILBrowserSavedSearches alloc] initWithSearchByDeviceNameText:savedSearchRealm.searchByDeviceName dBmValue:savedSearchRealm.dBmValue beaconTypes:beaconTypes isFavourite:savedSearchRealm.isFavouriteSetFilter isConnectable:savedSearchRealm.isConnectableSetFilter andIsSelected:NO];
    return browserSavedSearch;
}

# pragma mark - Filter Active Checker

- (BOOL)isFilterActive {
    if (![_searchByDeviceName isEqual:EmptyText]) {
        return YES;
    }
    if (_dBmValue != DefaultDBMValue) {
        return YES;
    }
    if (_isFavouriteFilterSet != NO) {
        return YES;
    }
    if (_isConnectableFilterSet != NO) {
        return YES;
    }
    for (SILBrowserBeaconType* beaconType in _beaconTypes) {
        if (beaconType.isSelected != NO) {
            return YES;
        }
    }
    return NO;
}

# pragma mark - String Representation of Saved Search

- (NSString*)getStringRepresentationForObjectAtIndex:(NSUInteger)index {
    SILBrowserSavedSearches* savedSearches = _savedSearches[index];
    NSString* rssiValueString = [NSString stringWithFormat:@"%ld", savedSearches.dBmValue];
    
    NSMutableString *beaconTypeString = [[NSMutableString alloc] init];
    for (SILBrowserBeaconType* beaconType in savedSearches.beaconTypes) {
        if (beaconType.isSelected) {
            if (![beaconTypeString isEqual:EmptyText]) {
                [beaconTypeString appendString:CommaAndSpaceText];
            }
            [beaconTypeString appendString:QuoteText];
            [beaconTypeString appendString:beaconType.beaconName];
            [beaconTypeString appendString:QuoteText];
        }
    }
        
    NSMutableString* stringRepresentation = [[NSMutableString alloc] initWithString:RSSITitle];
    [stringRepresentation appendString:rssiValueString];
    [stringRepresentation appendString:AppendingDBM];
    if (![beaconTypeString isEqual:EmptyText]) {
        [stringRepresentation appendString:BeaconTypeTitle];
        [stringRepresentation appendString:beaconTypeString];
    }
    
    if (![savedSearches.searchByDeviceNameText isEqual:EmptyText]) {
        [stringRepresentation appendString:SearchByDeviceNameTitle];
        [stringRepresentation appendString:QuoteText];
        [stringRepresentation appendString:savedSearches.searchByDeviceNameText];
        [stringRepresentation appendString:QuoteText];
    }
        
    if (savedSearches.isFavourite) {
        [stringRepresentation appendString:OnlyFavouritesTitle];
    }
    
    if (savedSearches.isConnectable) {
        [stringRepresentation appendString:OnlyConnectableTitle];
    }
    
    return stringRepresentation;
}

@end



