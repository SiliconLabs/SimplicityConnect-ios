//
//  DoorLockViewController.h
//  BlueGecko
//
//  Created by Mantosh Kumar on 03/10/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Matter/Matter.h>
#import <SVProgressHUD/SVProgressHUD.h>
NS_ASSUME_NONNULL_BEGIN

@interface DoorLockViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *clusterImage;
@property (weak, nonatomic) IBOutlet UIButton *doorOpenButton;
@property (weak, nonatomic) IBOutlet UIButton *doorLockButton;
@property (weak, nonatomic) IBOutlet UILabel *deviceCurrentStatusLabel;
@property (strong, nonatomic) NSNumber * nodeId;
@property (strong, nonatomic) NSNumber * endPoint;
@property (nonatomic, assign) dispatch_queue_t filterMainQueue;
@end

NS_ASSUME_NONNULL_END
