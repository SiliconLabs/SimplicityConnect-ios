//
//  SILConnectedPeripheralDataModel.h
//  SiliconLabsApp
//
//  Created by Kamil Czajka on 24/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#ifndef SILConnectedPeripheralDataModel_h
#define SILConnectedPeripheralDataModel_h

@interface SILConnectedPeripheralDataModel : NSObject

@property (nonatomic, strong, readwrite) CBPeripheral* peripheral;
@property (nonatomic, readwrite) BOOL isSelected;

- (instancetype)initWithPeripheral:(CBPeripheral*)peripheral andIsSelected:(BOOL)isSelected;

@end

#endif /* SILConnectedPeripheralDataModel_h */
