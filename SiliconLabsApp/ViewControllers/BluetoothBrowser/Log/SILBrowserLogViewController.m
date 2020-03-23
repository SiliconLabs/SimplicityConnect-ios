//
//  SILBrowserLogViewController.m
//  BlueGecko
//
//  Created by Kamil Czajka on 14/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILBrowserLogViewController.h"
#import "SILBrowserLogTableViewCell.h"
#import "UIImage+SILImages.h"
#import "SILBrowserLogViewModel.h"
#import "SILLogDataModel.h"
#import "NSString+SILBrowserNotifications.h"

@interface SILBrowserLogViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *filterLogViewContainer;
@property (weak, nonatomic) IBOutlet UITableView *logTableView;
@property (weak, nonatomic) IBOutlet UIButton *clearLogButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *filterLogButton;
@property (weak, nonatomic) IBOutlet UIImageView *backImage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *filterLogViewHeight;

@property (strong, nonatomic) SILBrowserLogViewModel* viewModel;

@end

@implementation SILBrowserLogViewController

UIEdgeInsets const ImageInsetsForShareButton = {0, 0, 0 ,8};

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupFilterLogViewContainer];
    [self registerNibs];
    [self setTableViewBehaviours];
    [self hideScrollIndicators];
    [self setAppearanceForFooterView];
    [self addGestureRecognizerForBackImage];
    [self addObserverForReloadTableView];
    [self setupViewModel];
}

- (void)setupFilterLogViewContainer {
    [_filterLogViewContainer setHidden:YES];
    _filterLogViewHeight.constant = 0;
}

- (void)registerNibs {
    _logTableView.delegate = self;
    _logTableView.dataSource = self;
    [_logTableView registerNib:[UINib nibWithNibName:NSStringFromClass([SILBrowserLogTableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([SILBrowserLogTableViewCell class])];
}

- (void)setTableViewBehaviours {
     _logTableView.separatorColor = [UIColor clearColor];
    _logTableView.rowHeight = UITableViewAutomaticDimension;
    _logTableView.estimatedRowHeight = 30.0;
}

- (void)hideScrollIndicators {
    [_logTableView setShowsHorizontalScrollIndicator:NO];
    [_logTableView setShowsVerticalScrollIndicator:NO];
}

- (void)setAppearanceForFooterView {
    [self setAppearanceForShareButton];
    [self setAppearanceForClearLogButton];
    [self setAppearanceForFilterLogButton];
    [self setAppearanceForBackImage];
}

- (void)setAppearanceForShareButton {
    _shareButton.layer.cornerRadius = 10.0;
    [_shareButton.titleLabel setFont:[UIFont robotoMediumWithSize:[UIFont getMiddleFontSize]]];
    _shareButton.titleLabel.textColor = [UIColor sil_backgroundColor];
    _shareButton.imageEdgeInsets = ImageInsetsForShareButton;
}

- (void)setAppearanceForClearLogButton {
    [_clearLogButton.titleLabel setFont:[UIFont robotoMediumWithSize:[UIFont getMiddleFontSize]]];
}

- (void)setAppearanceForFilterLogButton {
    [_filterLogButton.titleLabel setFont:[UIFont robotoMediumWithSize:[UIFont getMiddleFontSize]]];
}

- (void)setAppearanceForBackImage {
    _backImage.image = [[UIImage imageNamed:SILImageExitView] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (IBAction)filterLogTapped:(id)sender {
    BOOL isVisibleFilterLogViewContainer = _filterLogViewContainer.isHidden;
    if (isVisibleFilterLogViewContainer) {
        _filterLogViewHeight.constant = 40;
    } else {
        _filterLogViewHeight.constant = 0;
    }
    [_filterLogViewContainer setHidden:!isVisibleFilterLogViewContainer];
}

- (IBAction)shareButtonTapped:(id)sender {
    UIActivityViewController* sharingActivity = [[UIActivityViewController alloc] initWithActivityItems:@[[_viewModel getLogsString]] applicationActivities:nil];
    if (sharingActivity.popoverPresentationController != nil) {
        UIPopoverPresentationController* popOver = sharingActivity.popoverPresentationController;
        popOver.sourceView = _shareButton;
        popOver.sourceRect = CGRectMake(CGRectGetMidX(_shareButton.bounds), CGRectGetMidY(_shareButton.bounds), 0, -16);
        [popOver setPermittedArrowDirections:UIPopoverArrowDirectionDown];
    }
    [self presentViewController:sharingActivity animated:YES completion:nil];

}

- (void)addGestureRecognizerForBackImage {
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedBackImage:)];
    [_backImage addGestureRecognizer:tap];
}

- (void)tappedBackImage:(UIGestureRecognizer *)gestureRecognizer {
    [_delegate logViewBackButtonPressed];
}

- (void)addObserverForReloadTableView {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadLogTableView) name:SILNotificationReloadLogTableView object:nil];
}

- (void)setupViewModel {
    _viewModel = [SILBrowserLogViewModel sharedInstance];
}

# pragma mark - Log Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_viewModel.logs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SILBrowserLogTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILBrowserLogTableViewCell class]) forIndexPath:indexPath];
    SILLogDataModel* log = _viewModel.logs[indexPath.row];
    [cell setValues:log];
    return cell;
}

- (void)reloadLogTableView {
    [_logTableView reloadData];
}

- (IBAction)clearLogButtonƒWasTapped:(id)sender {
    [_viewModel clearLogs];
}

@end
