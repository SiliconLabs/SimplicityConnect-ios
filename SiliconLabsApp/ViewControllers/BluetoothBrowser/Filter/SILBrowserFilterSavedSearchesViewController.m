//
//  SILBrowserFilterSavedSearchesViewController.m
//  BlueGecko
//
//  Created by Kamil Czajka on 13/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILBrowserFilterSavedSearchesViewController.h"
#import "SILSavedSearchesTableViewCell.h"
#import "SILBrowserFilterViewModel.h"
#import "NSString+SILBrowserNotifications.h"

@interface SILBrowserFilterSavedSearchesViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *savedSearchesTableView;

@property (strong, nonatomic) SILBrowserFilterViewModel* viewModel;

@end

@implementation SILBrowserFilterSavedSearchesViewController

CGFloat const SavedSearchesRowHeight = 34.0;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerNibs];
    [self addObservers];
    [self setEstimatedHeightForRows];
    _viewModel = [SILBrowserFilterViewModel sharedInstance];
}

# pragma mark - Observers

- (void)addObservers {
    [self addObserverAtContentSize];
    [self addObserverForReloadSavedSearchesTableView];
}

- (void)addObserverAtContentSize {
    [_savedSearchesTableView addObserver:self forKeyPath:SILNotificationTableViewContentSize options:NSKeyValueObservingOptionNew context:nil];
}

- (void)addObserverForReloadSavedSearchesTableView {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSavedSearchesTableView:) name:SILNotificationReloadSavedSearchesTableViewHeight object:nil];
}

- (void)reloadSavedSearchesTableView:(NSNotification*)notification {
    [_savedSearchesTableView reloadData];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqual:SILNotificationTableViewContentSize]) {
        if (change[NSKeyValueChangeNewKey] != nil) {
            [_savedSearchesTableView layoutIfNeeded];
            CGFloat height = _savedSearchesTableView.contentSize.height;
            _viewModel.savedSearchesTableViewHeight = height;
        }
    }
}

# pragma mark - Table View

- (void)registerNibs {
    _savedSearchesTableView.delegate = self;
    _savedSearchesTableView.dataSource = self;
    [_savedSearchesTableView registerNib:[UINib nibWithNibName:NSStringFromClass([SILSavedSearchesTableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([SILSavedSearchesTableViewCell class])];
}

- (void)setEstimatedHeightForRows {
    _savedSearchesTableView.estimatedRowHeight = SavedSearchesRowHeight;
    _savedSearchesTableView.rowHeight = UITableViewAutomaticDimension;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_viewModel.savedSearches count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SILSavedSearchesTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILSavedSearchesTableViewCell class]) forIndexPath:indexPath];
    
    NSString* savedDescription = [_viewModel getStringRepresentationForObjectAtIndex:indexPath.row];
    [cell setValuesForSavedSearch:savedDescription andIndex:indexPath.row];
    if (_viewModel.savedSearches[indexPath.row].isSelected) {
        [cell customizeAppearanceForSelectedState];
    } else {
        [cell customizeAppearanceForUnselectedState];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_viewModel updateSavedSearches:indexPath.row];
    _viewModel.isActiveFilterFromSavedSearches = YES;
}

@end
