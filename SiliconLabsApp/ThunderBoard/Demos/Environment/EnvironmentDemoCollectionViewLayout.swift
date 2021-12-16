//
//  EnvironmentDemoCollectionViewLayout.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit

class EnvironmentDemoCollectionViewLayout : UICollectionViewLayout {

    fileprivate var cache = [UICollectionViewLayoutAttributes]()
    fileprivate var contentHeight = CGFloat(0.0)
    fileprivate var contentWidth: CGFloat {
        let insets = collectionView!.contentInset
        return collectionView!.bounds.width - (insets.left + insets.right)
    }
    
    override func prepare() {
        super.prepare()

        if cache.isEmpty {

            let numberOfColumns = 2
            let columnWidth = contentWidth / CGFloat(numberOfColumns)

            var position = [
                CGPoint(x: 0, y: 0),
                CGPoint(x: columnWidth, y: 0),
            ]

            var column = 0
            for item in 0 ..< collectionView!.numberOfItems(inSection: 0) {
                
                let indexPath = IndexPath(item: item, section: 0)

                let height = columnWidth + 40
                let frame = CGRect(x: position[column].x, y: position[column].y, width: columnWidth, height: height)

                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = frame
                cache.append(attributes)

                contentHeight = max(contentHeight, frame.maxY)
                position[column].y = position[column].y + height
                
                column = column >= (numberOfColumns - 1) ? 0 : (column + 1)
            }
        }
    }
    
    override var collectionViewContentSize : CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                layoutAttributes.append(attributes)
            }
        }
        return layoutAttributes
    }
}
