//
//  SILOTASetupViewController.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/10/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILOTASetupViewController.h"
#import "SILTextFieldEntryCell.h"
#import "SILOTAFirmwareUpdateViewModel.h"
#import "SILOTAFirmwareUpdate.h"
#import "SILOTAHUDView.h"
#import "SILAppearance.h"

typedef NS_ENUM(NSInteger, SILOTAFileSelecting) {
    SILOTAFileSelectingNone,
    SILOTAFileSelectingApp,
    SILOTAFileSelectingStack
};

static NSString * const kSILDocumentTypes = @"public.data";
static NSString * const kSILOTABadExtensionTitle = @"Wrong File Format";
static NSString * const kSILOTABadExtensionMessage = @"OTA update requires a .ebl or .gbl file. Please select a valid file.";
static NSString * const kSILOTABadExtensionActionTitle = @"OK";
static NSString * const kSILOTAChooseFileCTA = @"CHOOSE FILE";

@interface SILOTASetupViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate,
SILOTAFirmwareUpdateViewModelDelegate, UIDocumentPickerDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *otaMethodSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *otaModeSegmentedControl;
@property (weak, nonatomic) IBOutlet UITableView *fileSelectionTableView;
@property (weak, nonatomic) IBOutlet UIButton *startOTAButton;
@property (weak, nonatomic) IBOutlet SILOTAHUDView *hudView;
@property (strong) SILOTAHUDPeripheralViewModel *hudPeripheralViewModel;

@property (strong, nonatomic) SILOTAFirmwareUpdateViewModel *firmwareUpdateViewModel;
@property (nonatomic) SILOTAFileSelecting fileSelecting;

@property (weak, nonatomic) SILTextFieldEntryCell *lastSelectedCell;

@end

@implementation SILOTASetupViewController

#pragma mark - ViewController Lifecycle

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral withCentralManager:(SILCentralManager *)centralManager {
    self = [super init];
    if (self) {
        _hudPeripheralViewModel = [[SILOTAHUDPeripheralViewModel alloc] initWithPeripheral:peripheral withCentralManager:centralManager];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _fileSelectionTableView.estimatedRowHeight = 72.0;
    _fileSelectionTableView.rowHeight = UITableViewAutomaticDimension;
    [self setupViewModel];
    [self registerNibs];
    [self configureUIForFirmwareUpdateViewModel:self.firmwareUpdateViewModel];
    [_hudView stateDependentHidden:YES];
    _hudView.peripheralNameLabel.text = [_hudPeripheralViewModel peripheralName];
    _hudView.peripheralIdentifierLabel.text = [_hudPeripheralViewModel peripheralIdentifier];
    _hudView.mtuValueLabel.text = [_hudPeripheralViewModel peripheralMaximumWriteValueLength];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - Setup

- (void)setupViewModel {
    SILOTAFirmwareUpdate *firmwareUpdate = [SILOTAFirmwareUpdate new];
    self.firmwareUpdateViewModel = [[SILOTAFirmwareUpdateViewModel alloc] initWithOTAFirmwareUpdate:firmwareUpdate];
    self.firmwareUpdateViewModel.delegate = self;
}

- (void)registerNibs {
    NSString *cellClassString = NSStringFromClass([SILTextFieldEntryCell class]);
    [self.fileSelectionTableView registerNib:[UINib nibWithNibName:cellClassString bundle:nil] forCellReuseIdentifier:cellClassString];
}

#pragma mark - Actions

- (IBAction)didTapCancelButton:(id)sender {
    [self.delegate otaSetupViewControllerDidCancel:self];
}

- (IBAction)didSelectOTAMethodSegment:(UISegmentedControl *)sender {
    self.firmwareUpdateViewModel.updateMethod = ([sender selectedSegmentIndex] == 1) ? SILOTAMethodFull : SILOTAMethodPartial;
}

- (IBAction)didSelectOTAModeSegment:(UISegmentedControl *)sender {
    self.firmwareUpdateViewModel.updateMode = ([sender selectedSegmentIndex] == 1) ? SILOTAModeSpeed : SILOTAModeReliability;
}

- (IBAction)didTapStartOTAButton:(id)sender {
    [self.delegate otaSetupViewControllerEnterDFUModeForFirmwareUpdate:self.firmwareUpdateViewModel.otaFirmwareUpdate];
}

#pragma mark - Helpers

- (void)configureUIForFirmwareUpdateViewModel:(SILOTAFirmwareUpdateViewModel *)firmwareUpdateViewModel {
    const SILOTAMethod otaMethod = firmwareUpdateViewModel.updateMethod;
    const SILOTAMode otaMode = firmwareUpdateViewModel.updateMode;
    self.otaMethodSegmentedControl.selectedSegmentIndex = (otaMethod == SILOTAMethodPartial) ? 0 : 1;
    self.otaModeSegmentedControl.selectedSegmentIndex = (otaMode == SILOTAModeReliability) ? 0 : 1;
    self.startOTAButton.enabled = firmwareUpdateViewModel.shouldEnableStartOTAButton;
    [self.fileSelectionTableView reloadData];
}

#pragma mark - SILOTAFirmwareUpdateViewModelDelegate

- (void)firmwareViewModelDidUpdate:(SILOTAFirmwareUpdateViewModel *)firmwareViewModel {
    [self configureUIForFirmwareUpdateViewModel:firmwareViewModel];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.firmwareUpdateViewModel.fileViewModels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SILTextFieldEntryCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILTextFieldEntryCell class]) forIndexPath:indexPath];
    cell.callToAction = kSILOTAChooseFileCTA;
    cell.allowsTextEntry = NO;
    SILKeyValueViewModel *keyValueViewModel = self.firmwareUpdateViewModel.fileViewModels[indexPath.row];
    [cell configureWithKeyValueViewModel:keyValueViewModel];
    cell.clearTextHitView.tag = indexPath.row;
    UITapGestureRecognizer *tapInView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapInImageView:)];
    [cell.clearTextHitView addGestureRecognizer:tapInView];
    return cell;
}

-(void)tapInImageView:(UITapGestureRecognizer *)touch {
    if (touch.view.tag == 0) {
        self.firmwareUpdateViewModel.appFileURL = NULL;
    } else if (touch.view.tag == 1) {
        self.firmwareUpdateViewModel.stackFileURL = NULL;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        self.fileSelecting = SILOTAFileSelectingApp;
    } else if (indexPath.row == 1) {
        self.fileSelecting = SILOTAFileSelectingStack;
    }
    
    self.lastSelectedCell = [tableView cellForRowAtIndexPath:indexPath];
    [self beginDocumentPickFlow];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView.frame.size.height / 2 - 8;
}

- (void)beginDocumentPickFlow {
    [self presentDocumentPickerViewController];
}

- (void)presentDocumentPickerViewController {
    SILDocumentPickerViewController *documentPickerViewController = [[SILDocumentPickerViewController alloc]
                                                                    initWithDocumentTypes:@[kSILDocumentTypes]
                                                                    inMode:UIDocumentPickerModeImport];

    documentPickerViewController.delegate = self;
    documentPickerViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentViewController:documentPickerViewController animated:YES completion:nil];
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    [self handleDocumentPicker:controller didPickDocumentsAtURL:urls.firstObject];
}

- (void)handleDocumentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURL:(NSURL *)url {
    if (![self validExtensionForURL:url]) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:kSILOTABadExtensionTitle
                                                                       message:kSILOTABadExtensionMessage
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:kSILOTABadExtensionActionTitle style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  if (self.lastSelectedCell != nil) {
                                                                      [self beginDocumentPickFlow];
                                                                  }
                                                              }];
        
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    if (self.fileSelecting == SILOTAFileSelectingApp) {
        self.firmwareUpdateViewModel.appFileURL = url;
    } else if (self.fileSelecting == SILOTAFileSelectingStack) {
        self.firmwareUpdateViewModel.stackFileURL = url;
    }
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    
}

#pragma mark - SILPopoverViewControllerSizeConstraints

- (CGSize)popoverIPhoneSize {
    return CGSizeMake(300.0, 382.0);
}

#pragma mark - Helpers

- (BOOL)validExtensionForURL:(NSURL *)url {
    NSString *ext = [url pathExtension];
    return ([ext caseInsensitiveCompare:@"ebl"] == NSOrderedSame || [ext caseInsensitiveCompare:@"gbl"] == NSOrderedSame);
}

@end
