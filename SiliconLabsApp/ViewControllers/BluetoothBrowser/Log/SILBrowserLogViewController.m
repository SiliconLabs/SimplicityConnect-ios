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
@property (weak, nonatomic) IBOutlet UITableView *logTableView;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;

@property (strong, nonatomic) SILBrowserLogViewModel* viewModel;

@end

@implementation SILBrowserLogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerNibs];
    [self setTableViewBehaviours];
    [self hideScrollIndicators];
    [self setAppearanceForFooterView];
    [self addObserverForReloadTableView];
    [self setupViewModel];
    [self scrollToBottomIfNeeded];
    [self setupNavigationBar];
}

- (void)setupNavigationBar {
    [self setLeftAlignedTitle:@"Activity Log"];
    UIBarButtonItem *backBarButton = [UIBarButtonItem.alloc initWithImage:[UIImage systemImageNamed:@"chevron.left"] style:UIBarButtonItemStyleDone target:self action:@selector(backButtonTapped)];
    self.navigationItem.leftBarButtonItems = @[backBarButton, self.navigationItem.leftBarButtonItem];
    self.navigationItem.leftItemsSupplementBackButton = NO;
    
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem.alloc initWithImage:[UIImage systemImageNamed:@"clear"] style:UIBarButtonItemStyleDone target:self action:@selector(clearButtonTapped)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.viewModel.shouldScrollDownLogs = YES;
    [self scrollToBottomIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.tabBarController hideTabBarAndUpdateFrames];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.tabBarController showTabBarAndUpdateFrames];
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
}

- (void)setAppearanceForShareButton {
    _shareButton.layer.cornerRadius = _shareButton.bounds.size.width / 2;
    [_shareButton.titleLabel setFont:[UIFont robotoMediumWithSize:[UIFont getMiddleFontSize]]];
    _shareButton.titleLabel.textColor = [UIColor sil_backgroundColor];
}

- (IBAction)backButtonTapped {
    [self.navigationController popViewControllerAnimated:true];
}

- (IBAction)clearButtonTapped {
    [self.viewModel clearLogs];
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
    
    if (indexPath.row % 2 == 0) {
        cell.backgroundColor = UIColor.sil_backgroundColor;
    } else {
        cell.backgroundColor = UIColor.sil_bgWhiteColor;
    }
    return cell;
}

- (void)reloadLogTableView {
    [_logTableView reloadData];
    [self scrollToBottomIfNeeded];
}

- (void)scrollToBottomIfNeeded {
    NSUInteger logsCount = [_viewModel.logs count];
    if (self.viewModel.shouldScrollDownLogs && logsCount > 0) {
        NSIndexPath* destinationIndexPath = [NSIndexPath indexPathForRow:[_viewModel.logs count] - 1 inSection:0];
        [_logTableView scrollToRowAtIndexPath:destinationIndexPath
            atScrollPosition:UITableViewScrollPositionBottom
            animated:YES];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.viewModel.shouldScrollDownLogs = NO;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.viewModel.shouldScrollDownLogs = [self isLastDetectedRowVisible];
}

- (BOOL)isLastDetectedRowVisible {
    return self.logTableView.indexPathsForVisibleRows.lastObject.row + 1 == self.viewModel.logs.count;
}

@end
