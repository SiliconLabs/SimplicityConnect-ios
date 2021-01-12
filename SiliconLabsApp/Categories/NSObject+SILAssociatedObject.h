//
//  NSObject+SILAssociatedObject.h
//  BlueGecko
//
//  Created by Michal Lenart on 03/12/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject(SILAssociatedObject)

- (nullable id)sil_associatedObject:(NSString*)key;
- (void)sil_setAssociatedObject:(nullable id)object forKey:(NSString*)key;

@end

NS_ASSUME_NONNULL_END
