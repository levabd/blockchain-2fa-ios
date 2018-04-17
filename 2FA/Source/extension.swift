//
//  extension.swift
//  SmileLock-Example
//
//  Created by yuchen liu on 4/24/16.
//  Copyright © 2016 Recruit Lifestyle Co., Ltd. All rights reserved.
//

import UIKit
import Alamofire

enum ColorType: String {
    case blue = "20aee5"
    case textColor = "555555"
}

extension UIColor {
    
    class func hexStr(_ hexStr: String) -> UIColor {
        return UIColor.hexStr(hexStr, alpha: 1)
    }
    
    class func color(_ hexColor: ColorType) -> UIColor {
        return UIColor.hexStr(hexColor.rawValue, alpha: 1.0)
    }
    
    class func hexStr(_ str: String, alpha: CGFloat) -> UIColor {
        let hexStr = str.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: hexStr)
        var color: UInt32 = 0
        if scanner.scanHexInt32(&color) {
            let r = CGFloat((color & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((color & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(color & 0x0000FF) / 255.0
            return UIColor(red: r, green: g, blue: b , alpha: alpha)
        } else {
            print("Invalid hex string")
            return .white
        }
    }
    
}

extension String {
    
    //To check text field or String is blank or not
    var isBlank: Bool {
        get {
            let trimmed = trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return trimmed.isEmpty
        }
    }
    
    //Validate Email
    var isEmail: Bool {
        do {
            let regex = try NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", options: .caseInsensitive)
            return regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count)) != nil
        } catch {
            return false
        }
    }
    
    //validate PhoneNumber
    var isPhoneNumber: Bool {
        
        let charcter = NSCharacterSet(charactersIn: "+0123456789").inverted
        var filtered:String!
        let inputString:NSArray = self.components(separatedBy: charcter) as NSArray
        filtered = inputString.componentsJoined(by: "") as String
        return  self == filtered
        
    }
    
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}

