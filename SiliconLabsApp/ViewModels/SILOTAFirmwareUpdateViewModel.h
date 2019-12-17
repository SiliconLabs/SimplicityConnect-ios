//
//  SILOTAFirmwareUpdateViewModel.h
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/13/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILOTAFirmwareUpdate.h"
@class SILKeyValueViewModel;

@protocol SILOTAFirmwareUpdateViewModelDelegate;

@interface SILOTAFirmwareUpdateViewModel : NSObject

- (instancetype)initWithOTAFirmwareUpdate:(SILOTAFirmwareUpdate *)otaFirmwareUpdate;

@property (strong, nonatomic, readonly) SILOTAFirmwareUpdate *otaFirmwareUpdate;
@property (weak, nonatomic) id<SILOTAFirmwareUpdateViewModelDelegate> delegate;
@property (strong, nonatomic, readonly) NSArray<SILKeyValueViewModel *> *fileViewModels;
@property (nonatomic, readonly) BOOL shouldEnableStartOTAButton;
@property (nonatomic) SILOTAMethod updateMethod;
@property (nonatomic) SILOTAMode updateMode;
@property (strong, nonatomic) NSURL *appFileURL;
@property (strong, nonatomic) NSURL *stackFileURL;

@end

@protocol SILOTAFirmwareUpdateViewModelDelegate <NSObject>

- (void)firmwareViewModelDidUpdate:(SILOTAFirmwareUpdateViewModel *)firmwareViewModel;

@end
