//
//  SILDebugCharacteristicEnumerationListViewController.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/3/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDebugCharacteristicEnumerationListViewController.h"
#import "SILEnumerationFieldRowModel.h"
#import "SILCharacteristicTableModel.h"
#import "SILDebugEnumerationValueTableViewCell.h"
#import "SILBluetoothEnumerationModel.h"
#import "SILBluetoothFieldModel.h"
#import "UITableViewCell+SILHelpers.h"
#import "UIView+NibInitable.h"

@interface SILDebugCharacteristicEnumerationListViewController ()
@property (strong, nonatomic) SILEnumerationFieldRowModel *enumerationModel;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerHeightConstraint;
@property (strong, nonatomic) SILDebugEnumerationValueTableViewCell *sizingEnumCell;
@property (nonatomic) NSInteger valueToSet;
@property (nonatomic) BOOL canEdit;
@end

@implementation SILDebugCharacteristicEnumerationListViewController

#pragma mark - Lifecycle

- (instancetype)initWithEnumeration:(SILEnumerationFieldRowModel *)enumerationViewModel canEdit:(BOOL)canEdit {
    self = [super init];
    if (self) {
        self.enumerationModel = enumerationViewModel;
        self.valueToSet = -1;
        self.canEdit = canEdit;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerNibs];
    [self setUpText];
    [self updateForIdiom];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.headerHeightConstraint.constant = 90.0f;
        
        [self.view updateConstraints];
    }
}

- (void)updateForIdiom {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.specificTitle.font  = [self.specificTitle.font fontWithSize:24.0f];
        self.generalTitle.font  = [self.generalTitle.font fontWithSize:16.0f];
    }
}

#pragma mark - Setup

- (void)registerNibs {
    NSString *cellClassString = NSStringFromClass([SILDebugEnumerationValueTableViewCell class]);
    [self.popoverTable registerNib:[UINib nibWithNibName:cellClassString bundle:nil] forCellReuseIdentifier:cellClassString];
    self.sizingEnumCell = (SILDebugEnumerationValueTableViewCell *)[self.view initWithNibNamed:cellClassString];
}

- (void)setUpText {
    self.specificTitle.text = self.enumerationModel.fieldModel.name;
    self.generalTitle.text = @"Characteristic Field";
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.saveButton setTitleColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.26] forState:UIControlStateDisabled];
    self.saveButton.enabled = self.canEdit;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.enumerationModel.enumertations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SILDebugEnumerationValueTableViewCell *enumerationCell = [self.popoverTable dequeueReusableCellWithIdentifier:NSStringFromClass([SILDebugEnumerationValueTableViewCell class]) forIndexPath:indexPath];
    [self configureCell:enumerationCell atIndexPath:indexPath];
    return enumerationCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.valueToSet = indexPath.row;
    [self.popoverTable reloadData];
}

//Necessary for iOS7
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self configureCell:self.sizingEnumCell atIndexPath:indexPath];
    return [self.sizingEnumCell autoLayoutHeight];
}

- (void)configureCell:(SILDebugEnumerationValueTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    SILBluetoothEnumerationModel *enumeration = self.enumerationModel.enumertations[indexPath.row];
    cell.valueLabel.text = enumeration.value;
    if (self.valueToSet < 0) {
        self.valueToSet = self.enumerationModel.activeValue;
    }
    cell.activeCheckImageView.hidden = !(self.valueToSet == enumeration.key);
    [cell layoutIfNeeded];
}

#pragma mark - IBActions

- (IBAction)didTapCancel:(UIButton *)sender {
    [self.popoverDelegate didClosePopoverViewController:self];
}

- (IBAction)didTapSave:(UIButton *)sender {
    [self.editDelegate didSaveCharacteristic:self.enumerationModel.parentCharacteristicModel withAction:^{
        self.enumerationModel.activeValue = self.valueToSet;
        [self.popoverDelegate didClosePopoverViewController:self];
    }];
}

@end
