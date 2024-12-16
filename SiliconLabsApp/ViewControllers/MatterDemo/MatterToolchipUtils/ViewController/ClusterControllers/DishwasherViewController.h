//
//  DishwasherViewController.h
//  BlueGecko
//
//  Created by Mantosh Kumar on 26/09/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Matter/Matter.h>
#import <SVProgressHUD/SVProgressHUD.h>

NS_ASSUME_NONNULL_BEGIN

static NSInteger const totalWashTime = 600;

@interface DishwasherViewController : UIViewController <UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *dishwasherImage;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseResumeButton;
@property (weak, nonatomic) IBOutlet UILabel *currentStatusLabel;

@property (strong, nonatomic) NSNumber * nodeId;
@property (strong, nonatomic) NSNumber * endPoint;

@property (weak, nonatomic) IBOutlet UILabel *energyValueInTotalLabel;
@property (weak, nonatomic) IBOutlet UILabel *energyValueCurrentCycleLabel;
@property (weak, nonatomic) IBOutlet UILabel *energyValueInAveragePerCycleLabel;

@property (weak, nonatomic) IBOutlet UIView *energyView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalWashTimeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *powerImage;

@property (weak, nonatomic) IBOutlet UILabel *completedCycleLabel;

@property (nonatomic) NSInteger timeLeft; // Remaining time in seconds
@property (nonatomic) BOOL isRunning;
@property (nonatomic) BOOL isPaused;
@property (nonatomic, strong) NSTimer *timer; // Timer object
@property (nonatomic, strong) NSString *dishwasherCurrentState;
@property (nonatomic, strong) NSTimer *dishwasherTimer;



@end

NS_ASSUME_NONNULL_END
