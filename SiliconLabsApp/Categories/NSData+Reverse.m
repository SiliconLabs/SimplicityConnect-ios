//
//  NSData+Reverse.m
//  BlueGecko
//
//  Created by Hubert Drogosz on 27/07/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

#import "NSData+Reverse.h"

@implementation NSData (Reverse)

- (NSData *)reversed {
    NSMutableData* mutableData = self.mutableCopy;
    char *reversedBytes = mutableData.mutableBytes;
    
    for (int i = 0; i < self.length/2; i++) {
        char x = reversedBytes[i];
        reversedBytes[i] = reversedBytes[self.length - i - 1];
        reversedBytes[self.length - i - 1] = x;
    }
    
    return mutableData;
}

@end
