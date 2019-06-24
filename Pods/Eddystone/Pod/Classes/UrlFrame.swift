//
//  UrlFrame.swift
//  Pods
//
//  Created by Tanner Nelson on 8/24/15.
//
//
import Foundation

class UrlFrame: Frame {
    
    //MARK: Constants
    static let schemePrefixes = [
        "http://www.",
        "https:/www.",
        "http://",
        "https://"
    ]
    
    static let urlEncodings = [
        ".com/",
        ".org/",
        ".edu/",
        ".net/",
        ".info/",
        ".biz/",
        ".gov/",
        ".com",
        ".org",
        ".edu",
        ".net",
        ".info",
        ".biz",
        ".gov"
    ]
    
    //MARK: Properties
    var url: URL
    
    //MARK: Initializations
    init(url: URL) {
        self.url = url
        
        super.init()
    }
   
    //MARK: Class
    override class func frameWithBytes(_ bytes: [Byte]) -> UrlFrame? {
        var urlString = ""
        
        for (offset, byte) in bytes.enumerated() {
            switch offset {
            case 2:
                if byte < UrlFrame.schemePrefixes.count {
                    urlString += UrlFrame.schemePrefixes[byte]
                }
            case 3...bytes.count-1:
                if byte < UrlFrame.urlEncodings.count {
                    urlString += UrlFrame.urlEncodings[byte]
                } else {
                    let unicode = UnicodeScalar(byte)
                    let character = Character(unicode!)
                    urlString.append(character)
                }
            default:
                break
            }
            
        }
        
        if let url = URL(string: urlString) {
            return UrlFrame(url: url)
        } else {
            log("Invalid URL frame")
        }
        
        return nil
    }
    
}
