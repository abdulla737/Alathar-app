import Flutter
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Shared with the AlatharWidget extension (Lock Screen / Home Screen).
  static let appGroup = "group.com.hadeeth.alathar"
  private var widgetChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Show reminder notifications even while the app is open.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // «alathar/widget»: the app sends the widget data as one JSON string.
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AlatharWidgetSync") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "alathar/widget", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "update", let json = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      UserDefaults(suiteName: AppDelegate.appGroup)?.set(json, forKey: "alathar_widget")
      if #available(iOS 14.0, *) {
        WidgetCenter.shared.reloadAllTimelines()
      }
      result(nil)
    }
    widgetChannel = channel
  }
}
