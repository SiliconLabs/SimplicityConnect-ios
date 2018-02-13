//
//  SILOTAFirmwareFile.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/13/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILOTAFirmwareFile.h"

@implementation SILOTAFirmwareFile

- (instancetype)initWithFileURL:(NSURL *)url {
    self = [super initWithFileURL:url];
    if (self) {
        self.fileData = [[NSData alloc] initWithContentsOfURL:url];
    }
    return self;
}

@end
