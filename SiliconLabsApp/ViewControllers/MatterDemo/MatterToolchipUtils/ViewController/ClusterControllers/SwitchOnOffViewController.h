//
//  SwitchOnOffViewController.h
//  BlueGecko
//
//  Created by Mantosh Kumar on 03/10/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Matter/Matter.h>
#import <SVProgressHUD/SVProgressHUD.h>
NS_ASSUME_NONNULL_BEGIN

@interface SwitchOnOffViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *cellBGView;
@property (weak, nonatomic) IBOutlet UIButton *bindButton;
@property (weak, nonatomic) IBOutlet UIView *bindLightSwitchView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *noDeviceFoundView;


@property (strong, nonatomic) NSNumber * nodeId;
@property (strong, nonatomic) NSNumber * endPoint;
@property (strong, nonatomic) NSString * deviceType;
@property (strong, nonatomic) NSString * deviceName;

//@property (strong, nonatomic) NSDictionary *switchInfo;
@end

NS_ASSUME_NONNULL_END
