//
//  Crypto.swift
//  a2fa
//
//  Created by Allatrack on 4/13/18.
//  Copyright © 2018 Allatrack. All rights reserved.
//

import Foundation
import zlib

class CryptoUtils {
    
    class func randomString(length: Int) -> String {
        
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
    
    class func toMD5Hash(string: String) -> String {
        let messageData = string.data(using:.utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        
        return digestData.map { String(format: "%02hhx", $0) }.joined()
    }
    
    class func calculateApiKey(path: String, body: String, phoneNumber: String) -> String {
    
        let buf: [UInt8] = [97, 77, 105, 83, 77, 85, 118, 89, 109, 80, 71, 122, 57, 114]
        var salt = ""
        buf.withUnsafeBufferPointer { ptr in
            let s = String.decodeCString(ptr.baseAddress,
                                         as: UTF8.self,
                                         repairingInvalidCodeUnits: true)
            salt = (s?.result)!
        }
        let rhex = randomString(length: 17)
        
        let strData = body.data(using: .utf8)! // Conversion to UTF-8 cannot fail
        let crc = strData.withUnsafeBytes { crc32(0, $0, numericCast(strData.count)) }
        let bodyCrc32 = NSString(format:"%x", crc) // "%2x"
        
        let firstStr = "\(path)::body::\(bodyCrc32)::key::\(salt)::phone_number::\(phoneNumber)"
        
        // print(firstStr)
        
        let md5str = toMD5Hash(string: firstStr)
        // print(md5str)
        
        return md5str + rhex
    }
}
