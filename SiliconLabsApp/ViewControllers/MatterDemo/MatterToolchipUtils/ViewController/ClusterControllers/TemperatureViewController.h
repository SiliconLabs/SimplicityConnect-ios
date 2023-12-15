//
//  TemperatureViewController.h
//  BlueGecko
//
//  Created by Mantosh Kumar on 03/10/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Matter/Matter.h>
#import <SVProgressHUD/SVProgressHUD.h>
NS_ASSUME_NONNULL_BEGIN

@interface TemperatureViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *tempValueLabel;
@property (weak, nonatomic) IBOutlet UIButton *refressButton;
@property (weak, nonatomic) IBOutlet UILabel *deviceCurrentStatusLabel;
@property (strong, nonatomic) NSNumber * nodeId;
@property (strong, nonatomic) NSNumber * endPoint;

@end

NS_ASSUME_NONNULL_END
