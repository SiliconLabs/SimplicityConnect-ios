//
//  EVSEViewController.h
//  BlueGecko
//
//  Created by Mantosh Kumar on 21/08/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Matter/Matter.h>
#import "CircularProgressView.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "EVSEModeUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface EVSEViewController : UIViewController 

@property (weak, nonatomic) IBOutlet CircularProgressView *circularProgressView;
@property (weak, nonatomic) IBOutlet UIButton *modeButton;
@property (weak, nonatomic) IBOutlet UILabel *vehicleIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *evConnectionStatusLabel;

@property (strong, nonatomic) NSNumber * nodeId;
@property (strong, nonatomic) NSNumber * endPoint;

// Add to EVSEViewController.h or class extension
@property (nonatomic, strong) NSArray<MTREnergyEVSEModeClusterModeOptionStruct *> *supportedModeStructs;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *supportedModes;   // each: { label, mode, tags }
@property (nonatomic, strong) UIPickerView *modePicker; // if using a picker

@property (nonatomic, strong) NSArray<NSDictionary *> *parsedModes;   // each dict: label/mode/tags
@property (nonatomic, strong) NSArray<NSString *> *modeLabels;        // labels only for picker
@property (strong, nonatomic) NSString *selectedMode;
@property (strong, nonatomic) NSNumber *selectedModeId;


@end

NS_ASSUME_NONNULL_END
