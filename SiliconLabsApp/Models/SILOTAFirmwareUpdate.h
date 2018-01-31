//
//  SILOTAFirmwareUpdate.h
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/13/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SILOTAFirmwareFile;

typedef NS_ENUM(NSInteger, SILOTAMode) {
    SILOTAModePartial,
    SILOTAModeFull
};

@interface SILOTAFirmwareUpdate : NSObject

@property (strong, nonatomic) SILOTAFirmwareFile *appFile;
@property (strong, nonatomic) SILOTAFirmwareFile *stackFile;
@property (nonatomic) SILOTAMode updateMode;

@end
