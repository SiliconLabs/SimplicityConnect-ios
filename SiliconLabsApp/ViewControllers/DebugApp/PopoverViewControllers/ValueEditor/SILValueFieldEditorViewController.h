//
//  SILValueFieldEditorViewController.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/9/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILDebugPopoverViewController.h"
#import "SILCharacteristicEditEnabler.h"

@interface SILValueFieldEditorViewController : SILDebugPopoverViewController
@property (strong, nonatomic) id<SILCharacteristicEditEnablerDelegate> editDelegate;
- (instancetype)initWithValueFieldModel:(SILValueFieldRowModel *)valueModel;
@end
