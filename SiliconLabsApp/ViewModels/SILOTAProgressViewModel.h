//
//  SILOTAProgressViewModel.h
//  SiliconLabsApp
//
//  Created by Bob Gilmore on 3/27/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILBeacon.h"
#import "SILCentralManager.h"
#import "SILOTAFirmwareFile.h"
#import "SILOTAHUDPeripheralViewModel.h"
#import "SILProximityCalculator.h"
#import "CBPeripheral+Services.h"

#ifndef SILOTAProgressViewModel_h
#define SILOTAProgressViewModel_h

@interface SILOTAProgressViewModel : NSObject
@property (nonatomic) CGFloat progressFraction;
@property (nonatomic) NSInteger progressBytes;
@property (copy, nonatomic) NSString *statusString;
@property (copy, nonatomic) NSString *uploadType;
@property (nonatomic) SILOTAFirmwareFile *file;
@property (nonatomic) NSInteger totalNumberOfFiles;
@property (nonatomic) BOOL finished;
@property (nonatomic) BOOL uploadingFile;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral withCentralManager:(SILCentralManager *)centralManager;

- (NSString *)uploadRateForDisplay;
- (NSString *)percentageForDisplay;
- (NSString *)filePathForDisplay;
- (NSString *)fileSizeForDisplay;
- (NSString *)numberOfFilesForDisplay;
- (NSString *)statusStringForDisplay;
- (NSString *)finalUploadTimeForDisplay;
- (NSString *)finalUploadRateForDisplay;
- (NSString *)finalUploadBytesForDisplay;
- (SILOTAHUDPeripheralViewModel *)HUDPeripheralViewModel;

@end

#endif /* SILOTAProgressViewModel_h */
