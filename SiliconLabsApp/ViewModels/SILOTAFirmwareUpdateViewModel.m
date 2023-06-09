//
//  SILOTAFirmwareUpdateViewModel.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/13/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILOTAFirmwareUpdateViewModel.h"
#import "SILKeyValueViewModel.h"
#import "SILOTAFirmwareFile.h"

static NSString * const kSILKeyNameForPartialOTA = @"Application:";
static NSString * const kSILKeyNameForFullOTA = @"Apploader:";

@interface SILOTAFirmwareUpdateViewModel ()

@property (strong, nonatomic, readwrite) SILOTAFirmwareUpdate *otaFirmwareUpdate;

@end

@implementation SILOTAFirmwareUpdateViewModel

#pragma mark - Initializers

- (instancetype)initWithOTAFirmwareUpdate:(SILOTAFirmwareUpdate *)otaFirmwareUpdate {
    self = [super init];
    if (self) {
        _otaFirmwareUpdate = otaFirmwareUpdate;
        _updateMode = SILOTAModeReliability;
        _updateMethod = SILOTAMethodPartial;
    }
    return self;
}

#pragma mark - Properties

- (NSArray<SILKeyValueViewModel *> *)fileViewModels {
    NSMutableArray *mutableFileViewModels = [NSMutableArray new];

    SILKeyValueViewModel *fileViewModel = [SILKeyValueViewModel new];
    fileViewModel.valueString = self.otaFirmwareUpdate.appFile.fileURL.absoluteString;
    fileViewModel.keyString = kSILKeyNameForPartialOTA;
    [mutableFileViewModels addObject:fileViewModel];
    
    if (self.otaFirmwareUpdate.updateMethod == SILOTAMethodFull) {
        SILKeyValueViewModel *fileViewModel = [SILKeyValueViewModel new];
        fileViewModel.valueString = self.otaFirmwareUpdate.stackFile.fileURL.absoluteString;
        fileViewModel.keyString = kSILKeyNameForFullOTA;
        [mutableFileViewModels addObject:fileViewModel];
    }

    return [mutableFileViewModels copy];
}

- (BOOL)shouldEnableStartOTAButton {
    const BOOL isPartialMode = self.updateMethod == SILOTAMethodPartial;
    const BOOL isFullMode = self.updateMethod == SILOTAMethodFull;
    const BOOL isStackFileDefined = self.otaFirmwareUpdate.stackFile != nil;
    const BOOL isAppFileDefined = self.otaFirmwareUpdate.appFile != nil;
    const BOOL shouldEnableStartButtonForPartialMode = isPartialMode && isAppFileDefined;
    const BOOL shouldEnableStartButtonForFullMode = isFullMode && isStackFileDefined && isAppFileDefined;
    const BOOL shouldEnableStartButton = shouldEnableStartButtonForPartialMode || shouldEnableStartButtonForFullMode;
    
    return shouldEnableStartButton;
}

- (void)setUpdateMethod:(SILOTAMethod)updateMethod {
    _updateMethod = updateMethod;
    self.otaFirmwareUpdate.updateMethod = updateMethod;
    [self.delegate firmwareViewModelDidUpdate:self];
}

- (void)setUpdateMode:(SILOTAMode)updateMode {
    _updateMode = updateMode;
    self.otaFirmwareUpdate.updateMode = updateMode;
    [self.delegate firmwareViewModelDidUpdate:self];
}

- (void)setAppFileURL:(NSURL *)appFileURL {
    _appFileURL = appFileURL;
    self.otaFirmwareUpdate.appFile = [self firmwareFileWithFileURL:appFileURL];
    [self.delegate firmwareViewModelDidUpdate:self];
}

- (void)setStackFileURL:(NSURL *)stackFileURL {
    _stackFileURL = stackFileURL;
    self.otaFirmwareUpdate.stackFile = [self firmwareFileWithFileURL:stackFileURL];
    [self.delegate firmwareViewModelDidUpdate:self];
}

#pragma mark - Helper methods

- (SILOTAFirmwareFile *)firmwareFileWithFileURL:(NSURL *)url {
    return url == nil ? nil : [[SILOTAFirmwareFile alloc] initWithFileURL:url];
}

@end
