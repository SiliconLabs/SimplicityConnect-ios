
#pragma once

#import <Foundation/Foundation.h>
#import <Matter/Matter.h>

/**
 * Management of the CA key and IPK for our fabric.
 */

NS_ASSUME_NONNULL_BEGIN

@interface FabricKeys : NSObject <MTRKeypair>

@property (readonly, nonatomic, strong) NSData * ipk;

- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
