//
//  SILDebugCharacteristicEncodingFieldView.h
//  SiliconLabsApp
//
//  Created by Grzegorz Janosz on 30/09/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SILDebugCharacteristicEncodingFieldView;
@protocol SILDebugCharacteristicEncodingFieldViewDelegate <NSObject>

@required
- (void)copyButtonWasClicked;

@end


@interface SILDebugCharacteristicEncodingFieldView : UIView
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property(weak, nonatomic) id <SILDebugCharacteristicEncodingFieldViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
