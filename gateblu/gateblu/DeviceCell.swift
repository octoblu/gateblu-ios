//
//  DeviceCellView.swift
//  gateblu
//
//  Created by Jade Meskill on 1/7/15.
//  Copyright (c) 2015 Octoblu. All rights reserved.
//

import Foundation
import UIKit

class DeviceCell: UICollectionViewCell, UIWebViewDelegate {
  @IBOutlet weak var label: UILabel?
  @IBOutlet weak var webView: UIWebView?
  var device: Device?

  func webViewDidFinishLoad(webView: UIWebView) {
    let imageUrl = device?.getRemoteImageUrl()
    if imageUrl == nil {
      return;
    }
    print("loading image now \(imageUrl!) \(device!.online)");
    self.webView!.stringByEvaluatingJavaScriptFromString("window.updateImage('\(imageUrl!)', \(device!.online))");
  }
  
}