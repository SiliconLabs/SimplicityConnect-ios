//
//  SILFieldRequirementEnforcer.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/5/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SILFieldRequirementEnforcer <NSObject>
- (void)didMeetRequirement:(NSString *)requirement;
@end