//
//  SILOTAFirmwareUpdate.h
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/13/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SILOTAFirmwareFile;

typedef NS_ENUM(NSInteger, SILOTAMethod) {
    SILOTAMethodPartial,
    SILOTAMethodFull
};

typedef NS_ENUM(NSInteger, SILOTAMode) {
    SILOTAModeReliability,
    SILOTAModeSpeed
};

@interface SILOTAFirmwareUpdate : NSObject

@property (strong, nonatomic) SILOTAFirmwareFile *appFile;
@property (strong, nonatomic) SILOTAFirmwareFile *stackFile;
@property (nonatomic) SILOTAMethod updateMethod;
@property (nonatomic) SILOTAMode updateMode;

@end
