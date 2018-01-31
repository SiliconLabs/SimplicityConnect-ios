//
//  SILBluetoothXMLParser.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/19/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SILDoubleKeyDictionaryPair;

@interface SILBluetoothXMLParser : NSObject

+ (instancetype)sharedParser;
- (SILDoubleKeyDictionaryPair *)servicesDictionary;
- (SILDoubleKeyDictionaryPair *)characteristicsDictionary;
- (SILDoubleKeyDictionaryPair *)descriptorsDictionary;

@end
