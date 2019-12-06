import UIKit
import Flutter
import flutter_auth0

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {
    
    //Setup channel to send screenshot notification
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController;
    let screenshotChannel = FlutterMethodChannel(name: "foria.foriatickets.com/screenshot", binaryMessenger: controller.binaryMessenger);
    
    GeneratedPluginRegistrant.register(with: self)
    
    NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil, queue: OperationQueue.main) { notification in
        
        screenshotChannel.invokeMethod("SCREENSHOT_TAKEN", arguments: nil);
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    override func application( _ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:] ) -> Bool {
        return FlutterAuth0Plugin.application(app, open:url, options:options)
    }

    @available(iOS 9.0, *)
    override func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let controller = window.rootViewController as? FlutterViewController

        let channel = FlutterMethodChannel(name: "plugins.flutter.io/quick_actions", binaryMessenger: controller!.binaryMessenger)
        channel.invokeMethod("launch", arguments: shortcutItem.type)
    }
}
