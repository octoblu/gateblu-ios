//
//  Template.swift
//  gateblu
//
//  Created by Peter DeMartini on 6/1/15.
//  Copyright (c) 2015 Octoblu. All rights reserved.
//

import Foundation

class Template {
  class func getTemplateFromBundle(templateName: String, replaceValues: Dictionary<String, String>) -> String {
    print("templateName \(templateName)")
    let htmlFilePath = NSBundle.mainBundle()
        .pathForResource(templateName, ofType:"html")!
    do {
      var html = try String(contentsOfFile: htmlFilePath, encoding: NSUTF8StringEncoding)
      for (key, value) in replaceValues {
        html = html.stringByReplacingOccurrencesOfString("{{\(key)}}", withString: value, options: NSStringCompareOptions.LiteralSearch, range: nil)
      }
      return html
    } catch let error as NSError {
      print("Error: \(error)")
    }
    return ""
  }
}