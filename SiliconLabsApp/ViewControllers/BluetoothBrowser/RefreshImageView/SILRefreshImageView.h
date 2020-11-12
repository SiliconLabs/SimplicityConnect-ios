//
//  SILRefreshImageView.h
//  BlueGecko
//
//  Created by Grzegorz Janosz on 23/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SILRefreshImageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SILRefreshImageView : UIView

@property (strong, nonatomic) SILRefreshImageModel* model;
-(void)setup;

@end

NS_ASSUME_NONNULL_END
