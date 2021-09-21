//
//  SILBrowserLogViewModel.h
//  SiliconLabsApp
//
//  Created by Kamil Czajka on 21/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#ifndef SILBrowserLogViewModel_h
#define SILBrowserLogViewModel_h
#import "SILLogDataModel.h"

@interface SILBrowserLogViewModel : NSObject

@property (strong, nonatomic, readwrite) NSString *filterLogText;
@property (strong, nonatomic, readwrite) NSMutableArray<SILLogDataModel*>* logs;
@property (nonatomic, readwrite) BOOL shouldScrollDownLogs;

+ (instancetype)sharedInstance;
- (void)clearLogs;
- (NSString*)getLogsString;

@end


#endif /* SILBrowserLogViewModel_h */
