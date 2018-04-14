//
//  Crypto.swift
//  a2fa
//
//  Created by Allatrack on 4/13/18.
//  Copyright © 2018 Allatrack. All rights reserved.
//

import Foundation
import zlib

class CryptUtils {
    
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdef0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    func toMD5Hash(string: String) -> String {
        let messageData = string.data(using:.utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        
        return digestData.map { String(format: "%02hhx", $0) }.joined()
    }
    
    func calculateApiKey(_ path: String, body: String, phoneNumber: String) -> String {
    
        let salt = "\u{97}\u{77}\u{105}\u{83}\u{77}\u{85}\u{118}\u{89}\u{109}\u{80}\u{71}\u{122}\u{57}\u{114}"
        
        let rhex = randomString(length: 17)
        
        let strData = body.data(using: .utf8)! // Conversion to UTF-8 cannot fail
        let crc = strData.withUnsafeBytes { crc32(0, $0, numericCast(strData.count)) }
        let bodyCrc32 = NSString(format:"%x", crc) // "%2x"
        
        let firstStr = "\(path)::body::\(bodyCrc32)::key::\(salt)::phone_number::\(phoneNumber)"
        
        let md5str = toMD5Hash(string: firstStr)
        
        return md5str + rhex
    }
}
