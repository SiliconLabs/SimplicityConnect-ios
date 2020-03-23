//
//  SILOTAProgressViewController.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/15/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILOTAProgressViewController.h"
#import "EXTKeyPathCoding.h"
#import <KVOController/FBKVOController.h>
#import <MZTimerLabel/MZTimerLabel.h>
#import "SILBigRedButton.h"
#import "SILOTAHUDView.h"
#import "UICircularProgressRing.h"
@import UICircularProgressRing;

static NSString * const kSILTimerFormat = @"m:ss";

@interface SILOTAProgressViewController ()

@property (weak) SILOTAProgressViewModel *viewModel;
@property (strong) SILOTAHUDPeripheralViewModel *hudPeripheralViewModel;
@property (weak, nonatomic) IBOutlet UICircularProgressRing *progressRing;
@property (weak, nonatomic) IBOutlet UILabel *percentNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *uploadRateNumberLabel;
@property (weak, nonatomic) IBOutlet SILBigRedButton *doneButton;
@property (weak, nonatomic) IBOutlet UILabel *timerDisplayLabel;
@property (strong, nonatomic) MZTimerLabel *timerLabel;
@property (weak, nonatomic) IBOutlet UIView *interiorProgressView;
@property (weak, nonatomic) IBOutlet UIView *interiorCompletedView;
@property (weak) NSTimer *repeatingTimer;
@property (nonatomic, weak) IBOutlet SILOTAHUDView *hudView;

@end

const CGFloat kIndeterminateSpinnerIncrementAngle = 9.0f;
const CGFloat kIndeterminateSpinnerValue = 0.25f;
const CGFloat kIndeterminateSpinnerValuePlusEps = 0.251f;
const NSTimeInterval kIndeterminateSpinnerIncrementInterval = (NSTimeInterval)0.05;
const CGFloat kAngleAtTop = -90.0f;
const CGFloat kAngleAtTopWrapAround = 270.0f;

@implementation SILOTAProgressViewController
{
    FBKVOController *_KVOController;
}

#pragma mark - ViewController Lifecycle

- (instancetype)initWithViewModel:(SILOTAProgressViewModel *)viewModel {
    self = [super init];
    if (self) {
        _viewModel = viewModel;
        _hudPeripheralViewModel = [viewModel HUDPeripheralViewModel];
        [self addObservers];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.doneButton.enabled = NO;
    self.timerLabel = [[MZTimerLabel alloc] initWithLabel:self.timerDisplayLabel];
    self.timerLabel.timeFormat = kSILTimerFormat;
    _hudView.peripheralNameLabel.text = [_hudPeripheralViewModel peripheralName];
    _hudView.peripheralIdentifierLabel.text = [_hudPeripheralViewModel peripheralIdentifier];
    _hudView.mtuValueLabel.text = [_hudPeripheralViewModel peripheralMaximumWriteValueLength];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [_KVOController unobserveAll];
    self.timerLabel = nil;
}

#pragma mark - Public

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _uploadRateNumberLabel.text = [_viewModel uploadRateForDisplay];
}

#pragma mark - Actions

- (IBAction)didTapDoneButton:(id)sender {
    [self.delegate progressViewControllerDidPressDoneButton:self];
}

#pragma mark - SILPopoverViewControllerSizeConstraints

- (CGSize)popoverIPhoneSize {
    return CGSizeMake(300.0, 440.0);
}

- (CGSize)popoverIPadSize {
    return CGSizeMake(540.0, 440.0);
}

#pragma mark - UI Implementation

- (void)incrementIndeterminateSpinner:(NSTimer *)theTimer {
    _progressRing.startAngle = _progressRing.startAngle + kIndeterminateSpinnerIncrementAngle;
    _progressRing.endAngle = _progressRing.endAngle + kIndeterminateSpinnerIncrementAngle;
    CGFloat value = _progressRing.value;
    // Merely changing the start and end angles does not cause a repaint; only changing the
    // value will do so.  Trigger trivial changes in order to force the repaint.
    value = (value == kIndeterminateSpinnerValue) ? kIndeterminateSpinnerValuePlusEps : kIndeterminateSpinnerValue;
    _progressRing.value = value;
}

- (void)startIndeterminteSpin {
    if (_repeatingTimer == nil) {
        _progressRing.value = kIndeterminateSpinnerValue;
        _repeatingTimer = [NSTimer scheduledTimerWithTimeInterval:kIndeterminateSpinnerIncrementInterval
                                 target:self selector:@selector(incrementIndeterminateSpinner:)
                               userInfo:nil repeats:YES];
    }
}

- (void)stopIndeterminateSpin {
    [_repeatingTimer invalidate];
    _repeatingTimer = nil;
}

- (void)resetProgressRing {
    _progressRing.startAngle = kAngleAtTop;
    _progressRing.endAngle = kAngleAtTopWrapAround;
    _progressRing.value = 0.0f;
    _percentNumberLabel.text = [_viewModel percentageForDisplay];
}

- (void)uploadStarted {
    [self.timerLabel reset];
    [self resetProgressRing];
    [self.timerLabel start];
    self.hudView.fileCountLabel.text = _viewModel.numberOfFilesForDisplay;
    [self setLiveProgressDetailsHidden:NO];
    [self stopIndeterminateSpin];
}

- (void)uploadStopped {
    [self.timerLabel pause];
    [self setLiveProgressDetailsHidden:YES];
    [self startIndeterminteSpin];
}

- (void)uploadsCompleted {
    [self setLiveProgressDetailsHidden:YES];
    [self stopIndeterminateSpin];
    [self resetProgressRing];
    _interiorCompletedView.hidden = NO;
    _doneButton.enabled = YES;
    _hudView.finalUploadRateLabel.text = _viewModel.finalUploadRateForDisplay;
    _hudView.finalUploadTimeLabel.text = _viewModel.finalUploadTimeForDisplay;
    _hudView.finalUploadBytesLabel.text = _viewModel.finalUploadBytesForDisplay;
    _hudView.finishedSummaryView.hidden = NO;
}

- (void)statusStringUpdated {
    _hudView.fileInfoView.hidden = YES;
    _hudView.statusLabel.text = [_viewModel statusStringForDisplay];
    _hudView.statusLabel.hidden = NO;
    _hudView.finishedSummaryView.hidden = YES;
}

- (void)fractionUploadedUpdated {
    _progressRing.value = _viewModel.progressFraction;
    _percentNumberLabel.text = [_viewModel percentageForDisplay];
    _hudView.fileNameLabel.text = _viewModel.filePathForDisplay;
    _hudView.fileTotalBytesLabel.text = _viewModel.fileSizeForDisplay;
    _hudView.fileInfoView.hidden = NO;
    _hudView.statusLabel.hidden = YES;
    _hudView.finishedSummaryView.hidden = YES;
    _progressRing.hidden = NO;
}

- (void)setLiveProgressDetailsHidden:(BOOL)hidden {
    self.interiorProgressView.hidden = hidden;
}

#pragma mark - Observers

- (void)addObservers {
    _KVOController = [[FBKVOController alloc] initWithObserver:self retainObserved:NO];

    [self observeAtKeyPath:@keypath(_viewModel.file) block:^(SILOTAProgressViewController *controller, SILOTAProgressViewModel *viewModel, NSDictionary *change) {
        _hudView.fileNameLabel.text = _viewModel.filePathForDisplay;
    }];
    
    [self observeAtKeyPath:@keypath(_viewModel.finished) block:^(SILOTAProgressViewController *controller, SILOTAProgressViewModel *viewModel, NSDictionary *change) {
        [self uploadsCompleted];
    }];
    
    [self observeAtKeyPath:@keypath(_viewModel.progressBytes) block:^(SILOTAProgressViewController *controller, SILOTAProgressViewModel *viewModel, NSDictionary *change) {
        [self fractionUploadedUpdated];
    }];
    
    [self observeAtKeyPath:@keypath(_viewModel.progressFraction) block:^(SILOTAProgressViewController *controller, SILOTAProgressViewModel *viewModel, NSDictionary *change) {
        _uploadRateNumberLabel.text = [_viewModel uploadRateForDisplay];
    }];
    
    [self observeAtKeyPath:@keypath(_viewModel.statusString) block:^(SILOTAProgressViewController *controller, SILOTAProgressViewModel *viewModel, NSDictionary *change) {
        [self statusStringUpdated];
    }];
    
    [self observeAtKeyPath:@keypath(_viewModel.totalNumberOfFiles) block:^(SILOTAProgressViewController *controller, SILOTAProgressViewModel *viewModel, NSDictionary *change) {
        _hudView.fileCountLabel.text = _viewModel.numberOfFilesForDisplay;
    }];
    
    [self observeAtKeyPath:@keypath(_viewModel.uploadingFile) block:^(SILOTAProgressViewController *controller, SILOTAProgressViewModel *viewModel, NSDictionary *change) {
        if ([change[NSKeyValueChangeNewKey] boolValue] == YES) {
            [self uploadStarted];
        } else {
            [self uploadStopped];
        }
    } options:NSKeyValueObservingOptionNew];
    
    [self observeAtKeyPath:@keypath(_viewModel.uploadType) block:^(SILOTAProgressViewController *controller, SILOTAProgressViewModel *viewModel, NSDictionary *change) {
        _hudView.uploadTypeLabel.text = _viewModel.uploadType;
    }];
}

- (void)observeAtKeyPath:(NSString *)keyPath block:(FBKVONotificationBlock)block options:(NSKeyValueObservingOptions)options{
    [_KVOController observe:_viewModel keyPath:keyPath options:options block:block];
}

- (void)observeAtKeyPath:(NSString *)keyPath block:(FBKVONotificationBlock)block {
    [self observeAtKeyPath:keyPath block:block options:0];
}

@end
