//
//  SILBrowserBeaconType.h
//  SiliconLabsApp
//
//  Created by Kamil Czajka on 18/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#ifndef SILBrowserBeaconType_h
#define SILBrowserBeaconType_h

@interface SILBrowserBeaconType : NSObject

@property (strong, nonatomic, readonly) NSString *beaconName;
@property (nonatomic, readwrite) BOOL isSelected;

- (instancetype)initWithName:(NSString*)beaconName andSelection:(BOOL)isSelected;
- (void)modifySelection;

@end


#endif /* SILBrowserBeaconType_h */
