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
    userContentController.addScriptMessageHandler(handler, name: "managerNotification")
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
  
  func stopWebView(){
    self.view.removeFromSuperview()
  }
  
  func getGatebluHTML() -> String {
    let authController = controllerManager.getAuthController()
    let values = [
      "uuid": authController.uuid!,
      "token": authController.token!
    ]
    let html = Template.getTemplateFromBundle("gateblu", replaceValues: values)
    return html
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



