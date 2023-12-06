

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHIPUIViewUtils : NSObject
+ (UIView *)viewWithUITextField:(UITextField *)textField button:(UIButton *)button;
+ (UIStackView *)stackViewWithLabel:(UILabel *)label result:(UILabel *)result;
+ (UIView *)viewWithLabel:(UILabel *)label textField:(UITextField *)textField;
+ (UIView *)viewWithLabel:(UILabel *)label toggle:(UISwitch *)toggle;

+ (UIStackView *)stackViewWithLabel:(UILabel *)label buttons:(NSArray<UIButton *> *)buttons;
+ (UIStackView *)stackViewWithButtons:(NSArray<UIButton *> *)buttons;

+ (UILabel *)addTitle:(NSString *)title toView:(UIView *)view;

+ (NSString *)addDeviceTitle:(NSString *)deviceType;

@end

NS_ASSUME_NONNULL_END
