//
//  SILBrowserConnectionsViewController.m
//  BlueGecko
//
//  Created by Kamil Czajka on 14/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILBrowserConnectionsViewController.h"
#import "SILBrowserConnectionsTableViewCell.h"
#import "UIImage+SILImages.h"
#import "SILBrowserConnectionsViewModel.h"
#import "SILConnectedPeripheralDataModel.h"
#import "NSString+SILBrowserNotifications.h"

@interface SILBrowserConnectionsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *connectionsTableView;
@property (weak, nonatomic) IBOutlet UIButton *disconnectAllButton;
@property (weak, nonatomic) IBOutlet UIImageView *backImage;

@property (strong, nonatomic) SILBrowserConnectionsViewModel* viewModel;

@end

@implementation SILBrowserConnectionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerNibs];
    [self hideScrollIndicators];
    [self setAppearanceForFooterView];
    [self addGestureRecognizerForBackImage];
    _viewModel = [SILBrowserConnectionsViewModel sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableView) name:SILNotificationReloadConnectionsTableView object:nil];
}

- (IBAction)disconnectAllTapped:(id)sender {
    [_viewModel disconnectAllPeripheral];
    [_delegate connectionsViewBackButtonPressed];
}

- (void)registerNibs {
    _connectionsTableView.delegate = self;
    _connectionsTableView.dataSource = self;
    [_connectionsTableView registerNib:[UINib nibWithNibName:NSStringFromClass([SILBrowserConnectionsTableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([SILBrowserConnectionsTableViewCell class])];
}

- (void)hideScrollIndicators {
    [_connectionsTableView setShowsHorizontalScrollIndicator:NO];
    [_connectionsTableView setShowsVerticalScrollIndicator:NO];
}

- (void)setAppearanceForFooterView {
    [self setAppearanceForDisconnectAllButton];
    [self setAppearanceForBackImage];
}

- (void)setAppearanceForDisconnectAllButton {
    _disconnectAllButton.layer.cornerRadius = CornerRadiusForButtons;
    [_disconnectAllButton.titleLabel setFont:[UIFont robotoMediumWithSize:[UIFont getSmallFontSize]]];
    _disconnectAllButton.titleLabel.textColor = [UIColor sil_backgroundColor];
    _disconnectAllButton.backgroundColor = [UIColor sil_siliconLabsRedColor];
}

- (void)setAppearanceForBackImage {
    _backImage.image = [[UIImage imageNamed:SILImageExitView] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (void)addGestureRecognizerForBackImage {
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedBackImage:)];
    [_backImage addGestureRecognizer:tap];
}

- (void)tappedBackImage:(UIGestureRecognizer *)gestureRecognizer {
    [_delegate connectionsViewBackButtonPressed];
}

# pragma mark - Log Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_viewModel.peripherals count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SILBrowserConnectionsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILBrowserConnectionsTableViewCell class]) forIndexPath:indexPath];
    SILConnectedPeripheralDataModel* peripheral = _viewModel.peripherals[indexPath.row];
    [cell setDeviceName:peripheral.peripheral.name index:indexPath.row andIsSelected:peripheral.isSelected];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1.0;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    view.tintColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_viewModel updateConnectionsView:indexPath.row];
    [_delegate presentDetailsViewControllerForIndex:indexPath.row];
}

- (void)reloadTableView {
    [_connectionsTableView reloadData];
}

@end
