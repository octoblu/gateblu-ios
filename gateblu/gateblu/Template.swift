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
    println("templateName \(templateName)")
    var htmlFilePath = NSBundle.mainBundle()
        .pathForResource(templateName, ofType:"html")!
    var html = String(contentsOfFile: htmlFilePath, encoding: NSUTF8StringEncoding, error: nil)
    for (key, value) in replaceValues {
      html = html!.stringByReplacingOccurrencesOfString("{{\(key)}}", withString: value, options: nil, range: nil)
    }
    return html!
  }
}