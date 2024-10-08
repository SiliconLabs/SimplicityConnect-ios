

#import <Matter/Matter.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^DeviceAction)(uint64_t deviceId);

@interface DeviceSelector : UITextField <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate>
- (instancetype)init;
- (void)refreshDeviceList;
- (void)forSelectedDevices:(DeviceAction)action;
@end

NS_ASSUME_NONNULL_END
