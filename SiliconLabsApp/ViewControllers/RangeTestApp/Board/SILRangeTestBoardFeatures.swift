//
//  SILRangeTestBoardFeatures.swift
//  SiliconLabsApp Dev
//
//  Created by Piotr Sarna on 12/02/2019.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

import UIKit

class SILRangeTestBoardFeatures: NSObject {
    private static let MODEL_NUMBER_SEPARATOR = " - "
    
    static func features(basedOnModelNumber modelNumber: String?) -> SILRangeTestBoardFeatures? {
        let modelNumberComponents = modelNumber?.components(separatedBy: MODEL_NUMBER_SEPARATOR)
        let boardId = modelNumberComponents?.last?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        return SILRangeTestBoardFeatures(withBoardId: boardId)
    }
    
    let boardId: String
    
    lazy var isChannelNumberReadOnly: Bool = {
        let readOnlyBoards = ["brd4171", "brd4180", "brd4181"]
        
        return readOnlyBoards.filter({ boardId.starts(with: $0) }).count != 0
    }()
    
    private init?(withBoardId boardId: String?) {
        guard let boardId = boardId else {
            return nil
        }
        
        self.boardId = boardId
    }
    
}
