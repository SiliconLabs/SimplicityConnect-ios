//
//  SILApp+AttributedProfiles.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/26/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILApp.h"

@interface SILApp (AttributedProfiles)

- (NSAttributedString *)showcasedProfilesAttributedStringWithTraitCollection:(UITraitCollection *)traitCollection;
- (NSAttributedString *)showcasedProfilesAttributedStringWithUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom;

@end
