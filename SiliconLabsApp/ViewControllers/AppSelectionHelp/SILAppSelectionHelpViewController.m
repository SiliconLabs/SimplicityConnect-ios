//
//  SILAppSelectionHelpViewController.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/26/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILAppSelectionHelpViewController.h"

@interface SILAppSelectionHelpViewController ()

@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

- (IBAction)didTapOKButton:(id)sender;

@end

@implementation SILAppSelectionHelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString * const version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    self.descriptionTextView.text =
    @"Quickly deliver multiprotocol applications using Silicon Labs Wireless Gecko energy-friendly system-on-chip (SoC) devices and modules running the Silicon Labs’ wireless protocols software stacks.\n\
\n\
For more information visit: www.silabs.com/products/wireless";
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
