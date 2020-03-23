//
//  SILLogDataModel.h
//  SiliconLabsApp
//
//  Created by Kamil Czajka on 21/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#ifndef SILLogDataModel_h
#define SILLogDataModel_h

@interface SILLogDataModel : NSObject 

@property (nonatomic, strong, readwrite) NSString* timestamp;
@property (nonatomic, strong, readwrite) NSString* logDescription;

- (instancetype)initWithDesctiption:(NSString*)description;
+ (NSString*)prepareLogDescription:(NSString*)title andPeripheral:(CBPeripheral*)peripheral andError:(NSError*)error;
+ (NSString*)prepareLogDescription:(NSString *)title andCharacteristic:(CBCharacteristic*)characteristic andPeripheral:(CBPeripheral *)peripheral andError:(NSError *)error;
+ (NSString*)prepareLogDescription:(NSString *)title andDescriptor:(CBDescriptor*)descriptor andPeripheral:(CBPeripheral *)peripheral andError:(NSError *)error;

@end

#endif /* SILLogDataModel_h */
