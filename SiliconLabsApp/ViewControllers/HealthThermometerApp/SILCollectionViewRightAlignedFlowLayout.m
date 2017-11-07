//
//  SILCollectionViewRightAlignedFlowLayout.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/22/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILCollectionViewRightAlignedFlowLayout.h"

@implementation SILCollectionViewRightAlignedFlowLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *ret = [super layoutAttributesForElementsInRect:rect];
    for (UICollectionViewLayoutAttributes *attributes in ret) {
        attributes.frame = CGRectMake(self.collectionView.bounds.size.width - (attributes.frame.origin.x + attributes.frame.size.width),
                                      attributes.frame.origin.y,
                                      attributes.frame.size.width,
                                      attributes.frame.size.height);
    }
    return ret;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    attributes.frame = CGRectMake(self.collectionView.bounds.size.width - (attributes.frame.origin.x + attributes.frame.size.width),
                                  attributes.frame.origin.y,
                                  attributes.frame.size.width,
                                  attributes.frame.size.height);
    return attributes;
}

@end
