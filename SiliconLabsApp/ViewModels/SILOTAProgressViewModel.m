//
//  SILOTAProgressViewModel.m
//  SiliconLabsApp
//
//  Created by Bob Gilmore on 3/27/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILOTAProgressViewModel.h"

@interface SILOTAProgressViewModel ()
@property (weak, nonatomic) SILCentralManager *centralManager;
@end

const float kKilobitsPerByte = 8.0f/1000;
NSString * const kUnknownRateDisplay = @"";
const CGFloat kPercentageDisplayMax = 0.99f;

@implementation SILOTAProgressViewModel {
    NSDate *_startTime;
    __weak CBPeripheral *_peripheral;
    NSInteger _fileCount;
    NSInteger _totalUploadByteCount;
    NSTimeInterval _totalUploadTimeInterval;
}

#pragma mark - Public

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral withCentralManager:(SILCentralManager *)centralManager{
    self = [super init];
    if (self) {
        _centralManager = centralManager;
        _peripheral = peripheral;
        _fileCount = 0;
    }
    return self;
}

- (void)setUploadingFile:(BOOL)uploadingFile {
    if (uploadingFile) {
        _startTime = [NSDate date];
        _progressBytes = 0.0f;
        _progressFraction = 0.0f;
        _fileCount += 1;
    } else {
        if (_uploadingFile) {
            _totalUploadByteCount += _file.fileData.length;
            _totalUploadTimeInterval += -[_startTime timeIntervalSinceNow];
        }
    }
    _uploadingFile = uploadingFile;
}

#pragma mark - String Helpers

- (NSString *)uploadRateForDisplay {
    NSTimeInterval secondsElapsed = -[_startTime timeIntervalSinceNow];
    return [self uploadKbpsForBytes:_progressBytes inTimeInterval:secondsElapsed];
}

- (NSString *)percentageForDisplay {
    float fraction = MIN(_progressFraction, kPercentageDisplayMax);
    return [NSString stringWithFormat:@"%.f", fraction * 100];
}

- (NSString *)filePathForDisplay {
    return _file.fileURL.absoluteString;
}

- (NSString *)fileSizeForDisplay {
    return [self sizeStringForBytes:_file.fileData.length];
}

- (NSString*) numberOfFilesForDisplay {
    return [NSString stringWithFormat:@"%ld OF %ld", (long)_fileCount, (long)_totalNumberOfFiles];
}

- (NSString *)statusStringForDisplay {
    return [_statusString uppercaseString];
}

- (NSString *)finalUploadTimeForDisplay {
    NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
    formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    formatter.allowedUnits = NSCalendarUnitMinute | NSCalendarUnitSecond;
    return [formatter stringFromTimeInterval: _totalUploadTimeInterval];
}

- (NSString *)finalUploadBytesForDisplay {
    return [self sizeStringForBytes:_totalUploadByteCount];
}

- (NSString *)finalUploadRateForDisplay {
    NSString *rate = [self uploadKbpsForBytes:_totalUploadByteCount inTimeInterval:_totalUploadTimeInterval];
    return [NSString stringWithFormat:@"%@ Kbps", rate];
}

- (SILOTAHUDPeripheralViewModel *)HUDPeripheralViewModel {
    return [[SILOTAHUDPeripheralViewModel alloc] initWithPeripheral:_peripheral withCentralManager:_centralManager];
}

#pragma mark - Private

- (NSString *)uploadKbpsForBytes:(NSInteger)bytes inTimeInterval:(NSTimeInterval)time {
    float rate = kKilobitsPerByte * bytes / time;
    if (rate == INFINITY || isnan(rate)) {
        return kUnknownRateDisplay;
    }
    return [NSString stringWithFormat:@"%.01f", rate];
}

- (NSString *)sizeStringForBytes:(NSUInteger)bytes {
    if (bytes == 0) {
        return @"";
    }
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setUsesGroupingSeparator:YES];
    return [formatter stringFromNumber:[NSNumber numberWithUnsignedInteger:bytes]];
}

@end
