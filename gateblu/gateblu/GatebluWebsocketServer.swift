import Foundation
import PocketSocket

class GatebluWebsocketServer: NSObject, PSWebSocketServerDelegate {
  var server:PSWebSocketServer!
  var onMessage:((PSWebSocket, String) -> ())!
  var onStart: () -> ()
  
  init(onMessage: (PSWebSocket, String) -> (), onStart: () -> ()) {
    self.onStart = onStart
    self.onMessage = onMessage
    super.init()
    self.server = PSWebSocketServer(host: nil, port: 0xd00d)
    self.server.delegate = self
    self.server.start()
  }
  
  func pushToAll(data:NSData!) {
    
  }
  
  func send(webSocket: PSWebSocket, message:String?) {
    webSocket.send(message)
  }
  
  func serverDidStart(server:PSWebSocketServer!) {
    NSLog("GatebluWebsocketServer starting")
    onStart()
  }
  
  func serverDidStop(server:PSWebSocketServer!) {
    NSLog("GatebluWebsocketServer stopping")
  }
  
  func server(server:PSWebSocketServer!, acceptWebSocketWithRequest request:NSURLRequest) -> (Bool) {
    NSLog("GatebluWebsocketServer should accept request: \(request)")
    return true
  }
  
  func server(server:PSWebSocketServer!, webSocket:PSWebSocket!, didReceiveMessage message:AnyObject) {
    NSLog("GatebluWebsocketServer websocket did receive message: \(message)")
    onMessage(webSocket, "\(message)")
  }
  
  func server(server:PSWebSocketServer!, webSocketDidOpen webSocket:PSWebSocket!) {
    NSLog("GatebluWebsocketServer websocket did open \(webSocket)")
  }
  
  func server(server:PSWebSocketServer!, webSocket:PSWebSocket!, didCloseWithCode code:NSInteger, reason:String, wasClean:Bool) {
    NSLog("GatebluWebsocketServer websocket did close with code: \(code), reason: \(reason), wasClean: \(wasClean)")
  }
  func server(server:PSWebSocketServer!, webSocket:PSWebSocket!, didFailWithError error:NSError) {
    NSLog("GatebluWebsocketServer websocket did fail with error: \(error)")
  }
}
