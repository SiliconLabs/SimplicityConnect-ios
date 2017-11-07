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

static NSString * const kSILKeyNameForPartialOTA = @"APP";
static NSString * const kSILKeyNameForFullOTA = @"STACK";

@interface SILOTAFirmwareUpdateViewModel ()

@property (strong, nonatomic, readwrite) SILOTAFirmwareUpdate *otaFirmwareUpdate;

@end

@implementation SILOTAFirmwareUpdateViewModel

#pragma mark - Initializers

- (instancetype)initWithOTAFirmwareUpdate:(SILOTAFirmwareUpdate *)otaFirmwareUpdate {
    self = [super init];
    if (self) {
        _otaFirmwareUpdate = otaFirmwareUpdate;
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

    if (self.otaFirmwareUpdate.updateMode == SILOTAModeFull) {
        SILKeyValueViewModel *fileViewModel = [SILKeyValueViewModel new];
        fileViewModel.valueString = self.otaFirmwareUpdate.stackFile.fileURL.absoluteString;
        fileViewModel.keyString = kSILKeyNameForFullOTA;
        [mutableFileViewModels addObject:fileViewModel];
    }

    return [mutableFileViewModels copy];
}

- (BOOL)shouldEnableStartOTAButton {
    return (self.updateMode == SILOTAModePartial && self.otaFirmwareUpdate.appFile != nil) ||
    (self.updateMode == SILOTAModeFull && self.otaFirmwareUpdate.appFile != nil && self.otaFirmwareUpdate.stackFile != nil);
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
    if (url != nil) {
        return [[SILOTAFirmwareFile alloc] initWithFileURL:url];
    } else {
        return nil;
    }

}

@end
