//
//  SILBrowserLogViewModel.m
//  BlueGecko
//
//  Created by Kamil Czajka on 21/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILBrowserLogViewModel.h"
#import "NSString+SILBrowserNotifications.h"
#import "SILBluetoothBrowser+Constants.h"

@interface SILBrowserLogViewModel ()

@property (strong, nonatomic, readwrite) NSMutableArray<SILLogDataModel*>* allLogs;

@end

@implementation SILBrowserLogViewModel

#pragma mark - Initializers

+ (instancetype)sharedInstance {
    static SILBrowserLogViewModel *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SILBrowserLogViewModel alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.filterLogText = EmptyText;
        self.logs = [[NSMutableArray alloc] init];
        self.allLogs = [[NSMutableArray alloc] init];
        [self setObserverRegisterLogNotification];
        [self filterLogs];
    }
    return self;
}

- (void)setObserverRegisterLogNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(registerLogInViewModel:) name:SILNotificationRegisterLog object:nil];
}

- (void)postReloadLogTableViewNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationReloadLogTableView object:self userInfo:nil];
}

- (void)registerLogInViewModel:(NSNotification*)notification {
    NSDictionary* directory = notification.userInfo;
    NSString* description = directory[SILNotificationKeyDescription];
    SILLogDataModel* log = [[SILLogDataModel alloc] initWithDesctiption:description];
    [_allLogs addObject:log];
    [self filterLogs];
}

- (void)clearLogs {
    _allLogs = [[NSMutableArray alloc] init];
    _logs = [[NSMutableArray alloc] init];
    [self postReloadLogTableViewNotification];
}

- (void)setFilterLogText:(NSString *)filterLogText {
    if (_filterLogText != filterLogText) {
        _filterLogText = filterLogText;
        [self filterLogs];
    }
}

- (void)filterLogs {
    _logs = [[NSMutableArray alloc] init];
    for (SILLogDataModel* log in _allLogs) {
        SILLogDataModel* copyLog = [[SILLogDataModel alloc] init];
        copyLog.logDescription = log.logDescription;
        copyLog.timestamp = log.timestamp;
        [_logs addObject:copyLog];
    }

    if (![_filterLogText isEqualToString:EmptyText]) {
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"logDescription CONTAINS[cd] %@", _filterLogText];
        [_logs filterUsingPredicate:filterPredicate];
    }

    [self postReloadLogTableViewNotification];
}

- (NSString*)getLogsString {
    NSMutableString* logsString = [[NSMutableString alloc] initWithString:ShareLogsTitle];
    for (SILLogDataModel* log in _logs) {
        [logsString appendString:[NSString stringWithFormat: @"%@", log.timestamp]];
        [logsString appendString:[NSString stringWithFormat: @" %@\n", log.logDescription]];
    }
    
    return logsString;
}

@end
