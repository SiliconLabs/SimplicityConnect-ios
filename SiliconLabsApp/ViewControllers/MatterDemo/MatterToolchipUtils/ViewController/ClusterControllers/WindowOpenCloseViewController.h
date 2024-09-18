//
//  WindowOpenCloseViewController.h
//  BlueGecko
//
//  Created by Mantosh Kumar on 03/10/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Matter/Matter.h>
#import <SVProgressHUD/SVProgressHUD.h>
NS_ASSUME_NONNULL_BEGIN

#define kOFFSET_FOR_KEYBOARD 50.0

@interface WindowOpenCloseViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *clusterImage;
@property (weak, nonatomic) IBOutlet UIButton *openButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) NSNumber * nodeId;
@property (strong, nonatomic) NSNumber * endPoint;
@property (weak, nonatomic) IBOutlet UILabel *deviceCurrentStatusLabel;
@property (weak, nonatomic) IBOutlet UIButton *liftButton;
@property (weak, nonatomic) IBOutlet UIButton *tiltButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *windowViewTopConstraints;
@property (weak, nonatomic) IBOutlet UITextField *liftInputTextField;
@property (weak, nonatomic) IBOutlet UITextField *tiltInputTextField;

@end

NS_ASSUME_NONNULL_END
