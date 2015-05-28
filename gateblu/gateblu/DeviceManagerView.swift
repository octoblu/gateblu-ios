import UIKit
import CoreBluetooth
import WebKit
import SwiftyJSON

class DeviceManagerView: NSObject {
  var view:WKWebView!
  var lastAwoke:NSDate = NSDate()
  let controllerManager = ControllerManager()
  
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
    let controller = controllerManager.getViewController()
    let parentView = controller.view as UIView
  
    let fileString = getGatebluHTML()
    
    self.view.loadHTMLString(fileString, baseURL: NSURL(fileURLWithPath:"http://app.octoblu.com"))
    println("DeviceManager webview")
  
    parentView.addSubview(self.view)
  }
  
  func getGatebluHTML() -> String {
    let deviceManager = controllerManager.getDeviceManager()
    var meshbluJSON : String = "{uuid:\""
    meshbluJSON += deviceManager.uuid!
    meshbluJSON += "\",token:\""
    meshbluJSON += deviceManager.token!
    meshbluJSON += "\"}"
    var htmlFilePath = NSBundle.mainBundle().pathForResource("gateblu", ofType:"html")!
    var htmlString = String(contentsOfFile: htmlFilePath, encoding: NSUTF8StringEncoding, error: nil)
    htmlString = htmlString!.stringByReplacingOccurrencesOfString("{{meshbluJSON}}", withString: meshbluJSON, options: nil, range: nil)
    return htmlString!
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



