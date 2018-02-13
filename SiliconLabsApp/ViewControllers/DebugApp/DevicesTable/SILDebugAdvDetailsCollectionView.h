//
//  SILDebugAdvDetailCollectionView.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/15/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SILDebugAdvDetailsCollectionView : UICollectionView

@property (nonatomic) NSIndexPath *parentIndexPath;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeightConstraint;

@end
