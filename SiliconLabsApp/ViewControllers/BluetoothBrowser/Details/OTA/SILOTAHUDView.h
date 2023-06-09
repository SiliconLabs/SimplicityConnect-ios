//
//  SILOTAHUDView.h
//  SiliconLabsApp
//
//  Created by Bob Gilmore on 3/22/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SILOTAHUDView : UIView

@property (nonatomic, weak) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UIView *fileInfoView;
@property (weak, nonatomic) IBOutlet UIView *stateDependentView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIView *finishedSummaryView;
@property (weak, nonatomic) IBOutlet UILabel *fileNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *uploadTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *fileTotalBytesLabel;
@property (weak, nonatomic) IBOutlet UILabel *otaStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *fileCountLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constrainBottomSeparatorBelowFile;
@property (weak, nonatomic) IBOutlet UILabel *finalUploadRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *finalUploadTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *finalUploadBytesLabel;
@property (weak, nonatomic) IBOutlet UILabel *otaInfoLabel;

- (void)stateDependentHidden:(BOOL)hidden;

@end
