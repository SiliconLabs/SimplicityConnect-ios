//
//  OccupancySensorViewController.h
//  BlueGecko
//
//  Created by SovanDas Maity on 16/10/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SVProgressHUD/SVProgressHUD.h>
NS_ASSUME_NONNULL_BEGIN

@interface OccupancySensorViewController : UIViewController
@property (strong, nonatomic) NSNumber * nodeId;
@property (strong, nonatomic) NSNumber * endPoint;
@property (weak, nonatomic) IBOutlet UIImageView *occupancyImg;
@property (weak, nonatomic) IBOutlet UILabel *deviceCurrentStatusLabel;
@end

NS_ASSUME_NONNULL_END
