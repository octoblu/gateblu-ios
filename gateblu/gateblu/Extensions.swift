//
//  Extensions.swift
//  gateblu
//
//  Created by Jade Meskill on 12/19/14.
//  Copyright (c) 2014 Octoblu. All rights reserved.
//

import Foundation

extension String {
    
    func derosenthal() -> String {
        let regex = NSRegularExpression(pattern: "(\\w{8})(\\w{4})(\\w{4})(\\w{4})(\\w{12})", options: nil, error: nil)
        var muuid = NSMutableString(string: self)
        if count(self) <= 36 {
            regex?.replaceMatchesInString(muuid, options: nil, range: NSMakeRange(0, count(self)), withTemplate: "$1-$2-$3-$4-$5")
        }
        return NSString(string: muuid).uppercaseString;
    }
    
    /// Create NSData from hexadecimal string representation
    ///
    /// This takes a hexadecimal representation and creates a NSData object. Note, if the string has any spaces, those are removed. Also if the string started with a '<' or ended with a '>', those are removed, too. This does no validation of the string to ensure it's a valid hexadecimal string
    ///
    /// The use of `strtoul` inspired by Martin R at http://stackoverflow.com/a/26284562/1271826
    ///
    /// :returns: NSData represented by this hexadecimal string. Returns nil if string contains characters outside the 0-9 and a-f range.
  
    func dataFromHexadecimalString() -> NSData? {
      let trimmedString = self.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<> ")).stringByReplacingOccurrencesOfString(" ", withString: "")
      
      // make sure the cleaned up string consists solely of hex digits, and that we have even number of them
      
      var error: NSError?
      let regex = NSRegularExpression(pattern: "^[0-9a-f]*$", options: .CaseInsensitive, error: &error)
      let found = regex?.firstMatchInString(trimmedString, options: nil, range: NSMakeRange(0, count(trimmedString)))
      if found == nil || found?.range.location == NSNotFound || count(trimmedString) % 2 != 0 {
        return nil
      }
      
      // everything ok, so now let's build NSData
      
      let data = NSMutableData(capacity: count(trimmedString) / 2)
      
      for var index = trimmedString.startIndex; index < trimmedString.endIndex; index = index.successor().successor() {
        let byteString = trimmedString.substringWithRange(Range<String.Index>(start: index, end: index.successor().successor()))
        let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
        data?.appendBytes([num] as [UInt8], length: 1)
      }
      
      return data
    }
}

extension NSData {
    func hexString() -> NSString {
        var str = NSMutableString()
        let bytes = UnsafeBufferPointer<UInt8>(start: UnsafePointer(self.bytes), count:self.length)
        for byte in bytes {
            str.appendFormat("%02hhx", byte)
        }
        return str
    }
}

