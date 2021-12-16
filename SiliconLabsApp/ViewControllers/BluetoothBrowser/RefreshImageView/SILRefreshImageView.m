//
//  SILRefreshImageView.m
//  BlueGecko
//
//  Created by Grzegorz Janosz on 23/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILRefreshImageView.h"

@interface SILRefreshImageView () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UIView *refreshImageView;
@property (weak, nonatomic) IBOutlet UIImageView *refreshImage;
@property CGFloat gestureBeganContentOffsetValue;
@property CGFloat gestureLastOffsetValue;

@end

@implementation SILRefreshImageView

CGFloat const RefreshTopConstraintActionValue = 60;
CGFloat const RefreshTopConstraintHideValue = -30;
CGFloat const RefreshTopConstraintMaxValue = 2.5 * RefreshTopConstraintActionValue;

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];

    if (self) {
        [self commonInit];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self commonInit];
    }
    return self;
}

-(void)commonInit {
    [[NSBundle mainBundle] loadNibNamed:@"SILRefreshImageView" owner:self options:nil];
    [self addSubview:self.refreshImageView];
    self.refreshImageView.frame = self.bounds;
    
    _gestureBeganContentOffsetValue = 0;
    _gestureLastOffsetValue = 0;
}

-(void)layoutSubviews {
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    _refreshImageView.center = CGPointMake(width / 2, height / 2);
    _refreshImageView.layer.cornerRadius = width / 2;
}

-(void)setup {
    _refreshImageView.layer.masksToBounds = YES;
    _refreshImageView.layer.shadowColor = UIColor.blackColor.CGColor;
    _refreshImageView.layer.shadowRadius = 3;
    _refreshImageView.layer.shadowOpacity = 1;
    _refreshImageView.layer.shadowOffset = CGSizeZero;
    
    if(self.model) {
        self.model.topRefreshImageConstraint.constant = RefreshTopConstraintHideValue;
        [self setupGestureAndDelegates];
    }
}

-(void)setupGestureAndDelegates {
    UIPanGestureRecognizer *scrollViewPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveImage:)];
    scrollViewPanGestureRecognizer.delegate = self;
    [self.model.tableView addGestureRecognizer:scrollViewPanGestureRecognizer];
}


- (void)moveImage:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.model.emptyView];
    CGPoint velocity = [recognizer velocityInView:self.model.emptyView];
    CGFloat duration = fabs(self.gestureLastOffsetValue / velocity.y);
    NSInteger verticalChangeValue = translation.y - _gestureBeganContentOffsetValue;
    CGFloat contentOffsetY = self.model.tableView.contentOffset.y;
        
    if (verticalChangeValue < 0) {
        verticalChangeValue = 0;
    }
    
    if (contentOffsetY == 0) {
        switch (recognizer.state) {
            case UIGestureRecognizerStateEnded:
                [self animateRefreshingImageWithDuration:0.2];
                [self.model.tableView setScrollEnabled:YES];
                self.gestureLastOffsetValue = 0;
                break;
                
            case UIGestureRecognizerStateChanged:
                [self showAndManageRefreshingImage];
                self.gestureLastOffsetValue = fabs(verticalChangeValue - self.gestureLastOffsetValue);
                if (verticalChangeValue <= RefreshTopConstraintMaxValue) {
                    [self animateWithDuration: duration
                           andConstraintValue: RefreshTopConstraintHideValue + verticalChangeValue
                        withTransformRotation: M_PI_2 + verticalChangeValue / 20
                                andCompletion: nil];
                }
                break;
                
            default:
                break;
        }
    }
    
    if (recognizer.state == UIGestureRecognizerStateBegan && [self shouldRefreshUI:velocity contentOffsetY:contentOffsetY]) {
        [self showAndManageRefreshingImage];
        self.gestureBeganContentOffsetValue = contentOffsetY;
        self.gestureLastOffsetValue = contentOffsetY;
        [self.layer removeAllAnimations];
        [self animateRefreshingImageWithDuration:0.1];
    }
}

- (BOOL)shouldRefreshUI:(CGPoint)velocity contentOffsetY:(CGFloat)contentOffsetY {
    return velocity.y > 0 && contentOffsetY == 0;
}

- (void)showAndManageRefreshingImage {
    [self.model.tableView setScrollEnabled:NO];
    [self.refreshImageView setHidden:NO];
}

- (void)animateRefreshingImageWithDuration:(NSTimeInterval)duration {
    if (self.model.topRefreshImageConstraint.constant >= RefreshTopConstraintActionValue) {
        [self animateWithDuration:duration
               andConstraintValue:RefreshTopConstraintActionValue
            withTransformRotation:0
                    andCompletion:^{
                                    [self.refreshImageView setHidden:YES];
                                    self.model.topRefreshImageConstraint.constant = RefreshTopConstraintHideValue;
                                    self.model.reloadAction();
                                    }];
    } else {
        [self animateWithDuration:duration
               andConstraintValue:RefreshTopConstraintHideValue
            withTransformRotation:0
                    andCompletion:nil];
    }
}

- (void)animateWithDuration:(NSTimeInterval)duration andConstraintValue:(CGFloat)constraintValue
      withTransformRotation:(CGFloat)rotationValue andCompletion:(nullable void (^)(void))completion {
    [UIView animateWithDuration:duration
                     animations:^{
        self.model.topRefreshImageConstraint.constant = constraintValue;
        self.refreshImageView.transform = CGAffineTransformMakeRotation(rotationValue);
        [self.superview layoutIfNeeded];
    } completion: ^(BOOL finished){
        if (completion) {
            completion();
        }
    }];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
