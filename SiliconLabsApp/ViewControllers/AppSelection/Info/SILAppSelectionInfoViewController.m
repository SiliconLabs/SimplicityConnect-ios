//
//  SILAppSelectionInfoViewController.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/26/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILAppSelectionInfoViewController.h"

@interface SILAppSelectionInfoViewController ()

@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

- (IBAction)didTapOKButton:(id)sender;

@end

@implementation SILAppSelectionInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString * const version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    self.descriptionTextView.text = NSLocalizedString(@"app_info", @"");
    [self.descriptionTextView setTextContainerInset:UIEdgeInsetsZero];
    [self.descriptionTextView.textContainer setLineFragmentPadding:0];
    
    self.versionLabel.text = [NSString stringWithFormat: @"VERSION: %@", version];
}

- (IBAction)didTapOKButton:(id)sender {
    [self.delegate didFinishInfoWithAppSelectionInfoViewController:self];
}

#pragma mark - UIViewController Methods

- (CGSize)preferredContentSize {
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return CGSizeMake(600, 600);
    } else {
        return CGSizeMake(300, 520);
    }
}

@end
