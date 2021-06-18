//
//  DateExtension.swift
//  BlueGecko
//
//  Created by RAVI KUMAR on 12/12/19.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

import Foundation


extension Date {
  
    static func longStyleDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatString.fullTimeNoTimezone.formatString        
        return dateFormatter
    }
    
    func toString() -> String {
        let dateFormatter = Date.longStyleDateFormatter()
        
        return dateFormatter.string(from: self)
    }
    
    static func fromString(dateString: String) -> Date? {
        let dateFormatter = Date.longStyleDateFormatter()
        
        return dateFormatter.date(from: dateString)
    }
    
    
    func currentTimeMillis() -> Int64 {
        let nowDouble = self.timeIntervalSince1970
        return Int64(nowDouble*1000)
    }
    
}
