import UIKit
import CoreBluetooth
import WebKit

class DeviceManagerView: NSObject {
  var view:WKWebView!
  var lastAwoke:NSDate = NSDate()

  override init() {
    super.init()
    let userContentController = WKUserContentController()
    let handler = NotificationScriptMessageHandler()
    userContentController.addScriptMessageHandler(handler, name: "notification")
    let configuration = WKWebViewConfiguration()
    configuration.userContentController = userContentController
    let rect:CGRect = CGRectMake(0,0,0,0)
    self.view = WKWebView(frame: rect, configuration: configuration)
  }

  func startWebView() {
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let controller = appDelegate.window?.rootViewController as! ViewController
    let parentView = controller.view as UIView
  
    var htmlFilePath = NSBundle.mainBundle().pathForResource("gateblu", ofType:"html")!
    var fileString = String(contentsOfFile: htmlFilePath, encoding: NSUTF8StringEncoding, error: nil)
    self.view.loadHTMLString(fileString!, baseURL: NSURL(string: "http://app.octoblu.com"))
    println("DeviceManager webview")
  
    parentView.addSubview(self.view)
  }
  
  func wakeIfNotRecentlyAwoken() {
    let interval = self.lastAwoke.timeIntervalSinceNow
    if interval < 1 {
      wake()
    }
  }
  
  func wake() {
    if (UIApplication.sharedApplication().applicationState == UIApplicationState.Background) {
      dispatch_async(dispatch_get_main_queue(), {
        self.view.evaluateJavaScript("function(){}()", completionHandler: nil)
      })
    }
    self.lastAwoke = NSDate()
  }
  
}



