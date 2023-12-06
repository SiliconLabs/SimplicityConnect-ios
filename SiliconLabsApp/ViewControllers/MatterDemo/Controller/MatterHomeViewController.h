//
//  MatterHomeViewController.h
//  MatterMyTool
//
//  Created by Mantosh Kumar on 21/09/23.
//

#import <UIKit/UIKit.h>
#import <SVProgressHUD/SVProgressHUD.h>

typedef NS_ENUM(NSInteger, DeviceType) {
    matter_light = 257,
    matter_doorLock = 10,
    matter_window = 514,
    matter_switch = 259,
    matter_temprature = 769
};

NS_ASSUME_NONNULL_BEGIN

@interface MatterHomeViewController : UIViewController

@property (strong, nonatomic) NSArray * options;
@property (strong, nonatomic) NSString * deviceTypeStr;

@end

NS_ASSUME_NONNULL_END
