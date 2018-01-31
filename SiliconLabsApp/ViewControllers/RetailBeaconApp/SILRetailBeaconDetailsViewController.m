//
//  SILRetailBeaconDetailsViewController.m
//  SiliconLabsApp
//
//  Created by Max Litteral on 6/22/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILRetailBeaconDetailsViewController.h"
#import "SILBeaconRegistryEntryViewModel.h"
#import "SILDebugAdvDetailTableViewCell.h"
#import "SILBeaconDataModel.h"
#import "SILBeaconDataViewModel.h"
#import "SILRetailBeaconDetailsHeaderView.h"
#import "UIView+NibInitable.h"

@interface SILRetailBeaconDetailsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *uuidLabel;
@property (weak, nonatomic) IBOutlet UILabel *rssiValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *txValueLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray<SILBeaconDataViewModel *> *dataModels;
@property (strong, nonatomic) NSArray<SILBeaconDataViewModel *> *tlmDataViewModels;
@end

@implementation SILRetailBeaconDetailsViewController

#pragma MARK: - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.deviceNameLabel.text = self.entryViewModel.name;
    self.deviceTypeLabel.text = self.entryViewModel.type;
    self.uuidLabel.text = self.entryViewModel.entry.beacon.UUIDString.uppercaseString;
    self.rssiValueLabel.text = self.entryViewModel.formattedRSSI;
    self.txValueLabel.text = self.entryViewModel.formattedTx;

    [self setupTableView];

    NSArray<SILBeaconDataModel *> *beaconDataModels = [self beaconDataModels];
    NSMutableArray<SILBeaconDataViewModel *> *tempBeaconDataViewModels = [[NSMutableArray alloc] init];
    for (SILBeaconDataModel *dataModel in beaconDataModels) {
        [tempBeaconDataViewModels addObject:[[SILBeaconDataViewModel alloc] initWithBeaconDataModel:dataModel]];
    }
    self.dataModels = tempBeaconDataViewModels;

    NSArray<SILBeaconDataModel *> *tlmDataModels = [self tlmDataModels];
    NSMutableArray<SILBeaconDataViewModel *> *tempTLMDataViewModels = [[NSMutableArray alloc] init];
    for (SILBeaconDataModel *dataModel in tlmDataModels) {
        [tempTLMDataViewModels addObject:[[SILBeaconDataViewModel alloc] initWithBeaconDataModel:dataModel]];
    }
    self.tlmDataViewModels = tempTLMDataViewModels;

    [self.tableView reloadData];
}

- (CGSize)preferredContentSize {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return CGSizeMake(540, 600);
    } else {
        return CGSizeMake(296, 496);
    }
}

#pragma mark - Setup

- (void)setupTableView {
    self.tableView.estimatedRowHeight = 44;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.sectionHeaderHeight = 40;

    NSString *cellClassString = NSStringFromClass([SILDebugAdvDetailTableViewCell class]);
    [self.tableView registerNib:[UINib nibWithNibName:cellClassString bundle:nil] forCellReuseIdentifier:cellClassString];
}

- (NSArray<SILBeaconDataModel *> *)beaconDataModels {
    NSMutableArray<SILBeaconDataModel *> *mutableAdvModels = [[NSMutableArray alloc] init];

    if (self.entryViewModel.entry.beacon.type == SILBeaconTypeEddystone) {
        SILBeaconDataModel *urlModel = [[SILBeaconDataModel alloc] initWithValue:self.entryViewModel.entry.beacon.url.absoluteString ?: @"Unknown" type:BeaconModelTypeURL];
        [mutableAdvModels addObject:urlModel];
    }

    SILBeaconDataModel *instanceModel = [[SILBeaconDataModel alloc] initWithValue:self.entryViewModel.entry.beacon.instance.uppercaseString ?: @"Unknown" type:BeaconModelTypeInstance];
    [mutableAdvModels addObject:instanceModel];

    NSString *versionValue = [NSString stringWithFormat:@"%hu.%hu", self.entryViewModel.entry.beacon.major, self.entryViewModel.entry.beacon.minor];
    SILBeaconDataModel *versionModel = [[SILBeaconDataModel alloc] initWithValue:versionValue type:BeaconModelTypeVersion];
    [mutableAdvModels addObject:versionModel];

    return mutableAdvModels;
}

- (NSArray<SILBeaconDataModel *> *)tlmDataModels {
    NSMutableArray<SILBeaconDataModel *> *mutableAdvModels = [[NSMutableArray alloc] init];
    TLMData *tlmData = self.entryViewModel.beaconViewModel.beacon.tlmData;
    if (tlmData == nil) {
        return nil;
    }

    NSString *voltageValue = [NSString stringWithFormat:@"%f", tlmData.batteryVolts];
    SILBeaconDataModel *voltageModel = [[SILBeaconDataModel alloc] initWithValue:voltageValue type:BeaconModelTypeVoltage];
    [mutableAdvModels addObject:voltageModel];

    NSString *temperatureValue = [NSString stringWithFormat:@"%f", tlmData.temperature];
    SILBeaconDataModel *temperatureModel = [[SILBeaconDataModel alloc] initWithValue:temperatureValue type:BeaconModelTypeTemperature];
    [mutableAdvModels addObject:temperatureModel];

    NSString *advertisementCountValue = [NSString stringWithFormat:@"%li", (long)tlmData.advertisementCount];
    SILBeaconDataModel *advertisementCountModel = [[SILBeaconDataModel alloc] initWithValue:advertisementCountValue type:BeaconModelTypeAdvertisementCount];
    [mutableAdvModels addObject:advertisementCountModel];

    NSString *onTimeValueValue = [NSString stringWithFormat:@"%f", tlmData.onTime];
    SILBeaconDataModel *onTimeModel = [[SILBeaconDataModel alloc] initWithValue:onTimeValueValue type:BeaconModelTypeOnTime];
    [mutableAdvModels addObject:onTimeModel];

    return mutableAdvModels;
}

#pragma MARK: - Actions

- (IBAction)didTapOKButton:(id)sender {
    [self.delegate didFinishHelpWithBeaconDetailsViewController:self];
}

#pragma MARK: - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.tlmDataViewModels != nil && [self.tlmDataViewModels count] != 0) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [self.dataModels count];
    } else if (section == 1) {
        return [self.tlmDataViewModels count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SILDebugAdvDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILDebugAdvDetailTableViewCell class]) forIndexPath:indexPath];
    SILBeaconDataViewModel *dataModel;
    if (indexPath.section == 0) {
        dataModel = self.dataModels[indexPath.row];
    } else if (indexPath.section == 1) {
        dataModel = self.tlmDataViewModels[indexPath.row];
    }
    cell.detailTypeLabel.text = dataModel.typeString;
    cell.detailValueLabel.text = dataModel.valueString;
    return cell;
}

#pragma MARK: - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        SILRetailBeaconDetailsHeaderView *headerView = (SILRetailBeaconDetailsHeaderView *)[self.view initWithNibNamed:NSStringFromClass([SILRetailBeaconDetailsHeaderView class])];
        headerView.headerLabel.text = @"TLM DATA";
        return headerView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    }
    return 40;
}

@end
