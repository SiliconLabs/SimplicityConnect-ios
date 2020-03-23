//
//  SILBrowserFilterBeaconTypeViewController.m
//  BlueGecko
//
//  Created by Kamil Czajka on 13/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILBrowserFilterBeaconTypeViewController.h"
#import "SILBeaconTypeTableViewCell.h"
#import "SILBrowserFilterViewModel.h"
#import "NSString+SILBrowserNotifications.h"

@interface SILBrowserFilterBeaconTypeViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *beaconTypesTableView;

@property (strong, nonatomic) SILBrowserFilterViewModel* viewModel;

@end

@implementation SILBrowserFilterBeaconTypeViewController

CGFloat const BeaconTypeRowHeight = 34.0;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerNibs];
    [self addObservers];
    [self setEstimatedHeightForRows];
    _viewModel = [SILBrowserFilterViewModel sharedInstance];
}

#pragma mark - Observers

- (void)addObservers {
    [self addObserverForClearViewModelDataNotification];
    [self addObserverAtContentSize];
}

- (void)addObserverForClearViewModelDataNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableView) name:SILNotificationReloadFilterView object:nil];
}

- (void)addObserverAtContentSize {
    [_beaconTypesTableView addObserver:self forKeyPath:SILNotificationTableViewContentSize options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqual:SILNotificationTableViewContentSize]) {
        if (change[NSKeyValueChangeNewKey] != nil) {
            CGFloat height = _beaconTypesTableView.contentSize.height;
            _viewModel.beaconTypeTableViewHeight = height;
        }
    }
}

# pragma mark - Table View

- (void)registerNibs {
    _beaconTypesTableView.delegate = self;
    _beaconTypesTableView.dataSource = self;
    [_beaconTypesTableView registerNib:[UINib nibWithNibName:NSStringFromClass([SILBeaconTypeTableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([SILBeaconTypeTableViewCell class])];
}

- (void)setEstimatedHeightForRows {
    _beaconTypesTableView.estimatedRowHeight = BeaconTypeRowHeight;
    _beaconTypesTableView.rowHeight = UITableViewAutomaticDimension;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_viewModel.beaconTypes count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SILBeaconTypeTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILBeaconTypeTableViewCell class]) forIndexPath:indexPath];
    
    SILBrowserBeaconType* beaconType = _viewModel.beaconTypes[indexPath.row];
    [cell setValuesForBeaconTypeName:beaconType.beaconName andCheckmarkImage:beaconType.isSelected];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return BeaconTypeRowHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_viewModel.beaconTypes[indexPath.row] modifySelection];
    [_viewModel updateSavedSearches:-1];
    [_beaconTypesTableView reloadData];
}

- (void)updateTableView {
    [_beaconTypesTableView reloadData];
}

@end
