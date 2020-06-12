//
//  SILAppSelectionViewController.h
//  BlueGecko
//
//  Created by Kamil Czajka on 17/12/2019.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SILAppSelectionViewController : UIViewController

@property (strong, nonatomic) NSArray *appsArray;
@property BOOL isDisconnectedIntentionally;

@end

NS_ASSUME_NONNULL_END
