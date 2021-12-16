//
//  SILAppSelectionViewController.m
//  BlueGecko
//
//  Created by Anastazja Gradowska on 28/09/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

#import "SILAppSelectionHelpviewController.h"

@interface SILAppSelectionHelpViewController ()

@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

- (IBAction)didTapOKButton:(id)sender;

@end

@implementation SILAppSelectionHelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString * const version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    self.descriptionTextView.text = NSLocalizedString(@"app_info", @"");
    [self.descriptionTextView setTextContainerInset:UIEdgeInsetsZero];
    [self.descriptionTextView.textContainer setLineFragmentPadding:0];
    
    self.versionLabel.text = [NSString stringWithFormat: @"VERSION: %@", version];
}

- (IBAction)didTapOKButton:(id)sender {
    [self.delegate didFinishHelpWithAppSelectionHelpViewController:self];
}

#pragma mark - UIViewController Methods

- (CGSize)preferredContentSize {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return CGSizeMake(540, 390);
    } else {
        return CGSizeMake(296, 350);
    }
}

@end

