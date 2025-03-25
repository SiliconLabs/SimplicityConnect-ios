//
//  AirQualityViewController.h
//  BlueGecko
//
//  Created by Mantosh Kumar on 07/02/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Matter/Matter.h>
#import <SVProgressHUD/SVProgressHUD.h>

NS_ASSUME_NONNULL_BEGIN

@interface AirQualityViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UILabel *airQualityValueLabel;
@property (weak, nonatomic) IBOutlet UIButton *refressButton;

@property (weak, nonatomic) IBOutlet UILabel *airQualityStatus;


@property (strong, nonatomic) NSNumber * nodeId;
@property (strong, nonatomic) NSNumber * endPoint;

@end

NS_ASSUME_NONNULL_END
