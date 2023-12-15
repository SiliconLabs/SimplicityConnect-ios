//
//  SILSelectedMatterDeviceCell.h
//  BlueGecko
//
//  Created by Mantosh Kumar on 25/09/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@protocol DeviceActionDelegate <NSObject>
- (void) didDeleteAction:(NSDictionary *_Nullable)selectedDevice  tableCell:(UITableViewCell * _Nullable) cell;
@end

NS_ASSUME_NONNULL_BEGIN

@interface SILSelectedMatterDeviceCell : UITableViewCell

@property (nonatomic, retain) id <DeviceActionDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIView *deviceBGView;

@property (weak, nonatomic) IBOutlet UIImageView *selectedMatterImage;
@property (weak, nonatomic) IBOutlet UILabel *selectedMatterDeviceTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *uuidLabel;
@property (weak, nonatomic) NSMutableArray * deviceList;
@property (weak, nonatomic) IBOutlet UILabel *inactiveLbl;

- (void) setCell:(NSDictionary *) device;

@end

NS_ASSUME_NONNULL_END
