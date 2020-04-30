//
//  SILDebugAdvDetailsViewController.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/14/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILAdvertisementDataModel.h"
#import "SILDebugAdvDetailTableViewCell.h"
#import "SILDebugAdvDetailsViewController.h"
#import "SILDiscoveredPeripheral.h"
#import "SILDiscoveredPeripheralDisplayDataViewModel.h"
#import "SILDebugPopoverViewController.h"
#import "UITableViewCell+SILHelpers.h"
#import "UIView+NibInitable.h"
#import "SILDiscoveredPeripheralDisplayData.h"
#import "SILAdvertisementDataViewModel.h"
#import "SILBluetoothBrowser+Constants.h"

@interface SILDebugAdvDetailsViewController ()
@property (strong, nonatomic) SILDiscoveredPeripheralDisplayDataViewModel *peripheralViewModel;
@property (strong, nonatomic) SILDebugAdvDetailTableViewCell *sizingDetailCell;
@end

@implementation SILDebugAdvDetailsViewController


#pragma mark - Lifecycle


- (instancetype)initWithPeripheralViewModel:(SILDiscoveredPeripheralDisplayDataViewModel *)peripheralViewModel {
    self = [super init];
    if (self) {
        self.peripheralViewModel = peripheralViewModel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerNibs];
    self.generalTitle.text = self.peripheralViewModel.discoveredPeripheralDisplayData.discoveredPeripheral.peripheral.name ?: DefaultDeviceName;
}

#pragma mark - Setup 

- (void)registerNibs {
    NSString *cellClassString = NSStringFromClass([SILDebugAdvDetailTableViewCell class]);
    [self.popoverTable registerNib:[UINib nibWithNibName:cellClassString bundle:nil] forCellReuseIdentifier:cellClassString];
    self.sizingDetailCell = (SILDebugAdvDetailTableViewCell *)[self.view initWithNibNamed:cellClassString];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.peripheralViewModel.advertisementDataViewModelsForInfoView.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SILDebugAdvDetailTableViewCell *detailCell = [self.popoverTable dequeueReusableCellWithIdentifier:NSStringFromClass([SILDebugAdvDetailTableViewCell class]) forIndexPath:indexPath];
    [self configureCell:detailCell atIndexPath:indexPath];
    return detailCell;
}

//Necessary for iOS7
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self configureCell:self.sizingDetailCell atIndexPath:indexPath];
    return [self.sizingDetailCell autoLayoutHeight];
}

- (void)configureCell:(SILDebugAdvDetailTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    SILAdvertisementDataViewModel *detailModel = self.peripheralViewModel.advertisementDataViewModelsForInfoView[indexPath.row];
    cell.detailValueLabel.text = detailModel.valueString;
    cell.detailTypeLabel.text = detailModel.typeString;
    [cell layoutIfNeeded];
}

#pragma mark - IBActions

- (IBAction)didTapCancel:(UIButton *)sender {
    [self.popoverDelegate didClosePopoverViewController:self];
}

@end
