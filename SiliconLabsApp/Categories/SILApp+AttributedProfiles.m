//
//  SILApp+AttributedProfiles.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/26/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILApp+AttributedProfiles.h"
#import "UIColor+SILColors.h"

@implementation SILApp (AttributedProfiles)

- (NSAttributedString *)showcasedProfilesAttributedStringWithCompactSpacing:(BOOL)compactSpacing {
    NSString *spacing = compactSpacing ? @"    " : @"\n";
    CGFloat primarySize = compactSpacing ? 12 : 14;
    CGFloat secondarySize = compactSpacing ? 10 : 12;

    NSMutableAttributedString *ret = [[NSMutableAttributedString alloc] initWithString:@"" attributes:@{}];

    int count = 0;
    for (NSString *key in self.showcasedProfiles) {

        NSMutableAttributedString *part = [[NSMutableAttributedString alloc] initWithString:@""];
        [part appendAttributedString:[[NSAttributedString alloc] initWithString:self.showcasedProfiles[key]
                                                                     attributes:@{
                                                                                  NSFontAttributeName              : [UIFont helveticaNeueWithSize:primarySize],
                                                                                  NSForegroundColorAttributeName   : [UIColor sil_boulderColor],
                                                                                  }]];
        [part appendAttributedString:[[NSAttributedString alloc] initWithString:spacing]];
        [part appendAttributedString:[[NSAttributedString alloc] initWithString:key
                                                                     attributes:@{
                                                                                  NSFontAttributeName              : [UIFont helveticaNeueWithSize:secondarySize],
                                                                                  NSForegroundColorAttributeName   : [UIColor sil_silverChaliceColor],
                                                                                  }]];

        [ret appendAttributedString:part];
        if (count < self.showcasedProfiles.count - 1) {
            [ret appendAttributedString:[[NSAttributedString alloc] initWithString:spacing]];
            [ret appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        }

        count++;
    }

    return ret;
}

- (NSAttributedString *)showcasedProfilesAttributedStringWithTraitCollection:(UITraitCollection *)traitCollection {
    return [self showcasedProfilesAttributedStringWithCompactSpacing:traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone];
}

- (NSAttributedString *)showcasedProfilesAttributedStringWithUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom {
    return [self showcasedProfilesAttributedStringWithCompactSpacing:userInterfaceIdiom == UIUserInterfaceIdiomPhone];
}

@end
