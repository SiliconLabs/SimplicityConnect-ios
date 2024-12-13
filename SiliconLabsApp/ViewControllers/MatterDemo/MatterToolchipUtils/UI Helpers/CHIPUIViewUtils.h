

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Matter Device Types
static NSString * _Nullable const DimmingLight = @"257";
static NSString * _Nullable const EnhancedColorLight = @"269";
static NSString * _Nullable const OnOffLight = @"256";
static NSString * _Nullable const TemperatureColorLight = @"268";

static NSString * _Nullable const WindowCover = @"514";
static NSString * _Nullable const DoorLock = @"10";
static NSString * _Nullable const Thermostat = @"769";
static NSString * _Nullable const Plug = @"267";
static NSString * _Nullable const TemperatureSensor = @"770";
static NSString * _Nullable const OccupancySensor = @"263";
static NSString * _Nullable const ContactSensor = @"21";
static NSString * _Nullable const Switch = @"259";

static NSString * _Nullable const Dishwasher = @"117";

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
