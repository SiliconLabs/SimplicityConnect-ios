//
//  SILAttributeTableModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/6/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "SILDescriptorTableModel.h"
#import "SILBluetoothBrowser+Constants.h"

@interface SILDescriptorTableModel ()

@property (strong, nonatomic) SILBrowserDescriptorValueParser* parser;

@end

@implementation SILDescriptorTableModel

@synthesize isExpanded;
@synthesize hideTopSeparator;

- (instancetype)initWithDescriptor:(CBDescriptor *)descriptor {
    self = [super init];
    if (self) {
        self.descriptor = descriptor;
        self.isExpanded = NO;
        self.shouldReadValue = NO;
        self.valueLinesNumber = 0;
        self.parser = [[SILBrowserDescriptorValueParser alloc] initWithDescriptor:descriptor];
    }
    return self;
}

#pragma mark - SILGenericAttributeTableModel

- (BOOL)canExpand {
    return NO;
}

- (void)toggleExpansionIfAllowed {
    //can't expand
}

- (void)setShouldReadValue:(BOOL)shouldReadValue {
    _shouldReadValue = shouldReadValue;
    if (shouldReadValue) {
        self.valueLinesNumber = self.parser.valueLinesNumber;
    }
}

- (NSString *)hexUuidString {
    return [self.descriptor getHexUuidValue];
}

- (NSString*)uuidString {
    return self.descriptor.UUID.UUIDString;
}

- (NSString *)name {
    return EmptyText;
}

- (NSString*)getDescriptorName {
    return [self.parser getDescriptorName];
}

- (NSString*)getFormattedValue {
    return [self.parser getFormattedValue];
}

- (NSAttributedString*)getAttributedDescriptor {
    NSString* name = [self getDescriptorName];
    NSString* hexUUID = [self hexUuidString];
    NSMutableAttributedString* result = [NSMutableAttributedString.alloc initWithString: [NSString stringWithFormat:@"%@\n", name]];
    NSMutableAttributedString* uuidString = [NSMutableAttributedString.alloc initWithString:[NSString stringWithFormat:@"UUID: %@", hexUUID]];
    
    [uuidString addAttribute:NSForegroundColorAttributeName value:[UIColor sil_masala50pcColor] range:NSMakeRange(0, 5)];
    [result appendAttributedString:uuidString];
    
    if (self.shouldReadValue) {
        NSString* formattedValue = [self getFormattedValue];
        NSMutableAttributedString* valueString = [NSMutableAttributedString.alloc initWithString:[NSString stringWithFormat:@"\nValue: %@", formattedValue]];
        [valueString addAttribute:NSForegroundColorAttributeName value:[UIColor sil_masala50pcColor] range:NSMakeRange(1, 6)];
        [result appendAttributedString:valueString];
    }

    return result;
}

@end
