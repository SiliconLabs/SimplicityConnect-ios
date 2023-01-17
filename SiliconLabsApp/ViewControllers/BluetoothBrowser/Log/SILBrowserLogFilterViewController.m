//
//  SILBrowserLogFilterViewController.m
//  BlueGecko
//
//  Created by Kamil Czajka on 29/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILBrowserLogFilterViewController.h"
#import "SILBrowserLogViewModel.h"

@interface SILBrowserLogFilterViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *inputFilterTextView;
@property (weak, nonatomic) IBOutlet UIImageView *clearTextImageView;

@property (strong, nonatomic) SILBrowserLogViewModel* viewModel;

@end

@implementation SILBrowserLogFilterViewController

NSString* const FilterPlaceholder = @"Filter...";
NSString* const EmptyFilterText = @"";
NSString* const ResignFirstResponderText = @"\n";

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupInputFilterTextView];
    [self setupGestureForClearTextImageView];
    [self setupViewModel];
    [self addObserverForKeyboardHide];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateFilterTextViewState];
}

- (void)updateFilterTextViewState {
    _inputFilterTextView.text = _viewModel.filterLogText;
    [self textViewDidEndEditing:_inputFilterTextView];
    [self manageClearImageState];
}

- (void)setupInputFilterTextView {
    _inputFilterTextView.textContainer.maximumNumberOfLines = 1;
    _inputFilterTextView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
    _inputFilterTextView.delegate = self;
    [_inputFilterTextView setFont:[UIFont robotoMediumWithSize:[UIFont getMiddleFontSize]]];
    _inputFilterTextView.textColor = [UIColor sil_subtleTextColor];
    _inputFilterTextView.text = FilterPlaceholder;
    _inputFilterTextView.autocorrectionType = UITextAutocorrectionTypeNo;
    [_clearTextImageView setHidden:YES];
}

- (void)setupViewModel {
    _viewModel = [SILBrowserLogViewModel sharedInstance];
}

- (void)addObserverForKeyboardHide {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

# pragma mark - Text View Delegates

- (void)textViewDidChange:(UITextView *)textView {
    [self manageClearImageState];
    [self updateFilterTextViewModel];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:ResignFirstResponderText]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [self discardPlaceholderIfNeeded];
    [self manageClearImageState];
    [textView becomeFirstResponder];
}

- (void)manageClearImageState {
    if (([_inputFilterTextView.text isEqualToString:EmptyFilterText] || [_inputFilterTextView.text isEqualToString:FilterPlaceholder]) == false) {
        [self showClearImageForFilter];
    } else {
        [self hideClearImageForFilter];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [self setPlaceholderIfNeeded];
    [textView resignFirstResponder];
}

- (void)discardPlaceholderIfNeeded {
    if ([_inputFilterTextView.text isEqualToString:FilterPlaceholder]) {
        _inputFilterTextView.text = EmptyFilterText;
    }
}

- (void)setPlaceholderIfNeeded {
    if ([_inputFilterTextView.text isEqualToString:EmptyFilterText]) {
        _inputFilterTextView.text = FilterPlaceholder;
    }
}

- (void)updateFilterTextViewModel {
    if ([_inputFilterTextView.text isEqualToString:FilterPlaceholder]) {
        _viewModel.filterLogText = EmptyFilterText;
    } else {
        _viewModel.filterLogText = _inputFilterTextView.text;
    }
}

# pragma mark - Filter Clear Image

- (void)setupGestureForClearTextImageView {
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(performClearActionForFilterTextView:)];
    [_clearTextImageView addGestureRecognizer:tap];
}

- (void)performClearActionForFilterTextView:(UITapGestureRecognizer*)gestureRecognizer {
    _inputFilterTextView.text = EmptyFilterText;
    _viewModel.filterLogText = EmptyFilterText;
    if ([_inputFilterTextView isFirstResponder] == false) {
        [self textViewDidEndEditing:_inputFilterTextView];
    }
    [self hideClearImageForFilter];
}

- (void)showClearImageForFilter {
    [_clearTextImageView setHidden:NO];
}

- (void)hideClearImageForFilter {
    [_clearTextImageView setHidden:YES];
}

- (void)keyboardDidHide:(NSNotification*)notification {
    if ([_inputFilterTextView isFirstResponder] == false) {
         [self textViewDidEndEditing:_inputFilterTextView];
     }
}

@end
