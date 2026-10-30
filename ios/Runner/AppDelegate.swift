import Flutter
import UIKit
import AVFoundation
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  private var pipHandler: PiPMethodChannel?
  private var airPlayHandler: AirPlayHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("AVAudioSession setup error: \(error)")
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Registered like a plugin (not in registerCustomChannels) because Dart
    // calls it during startup, before the view controller is attached.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NotificationTrayHandler") {
      NotificationTrayHandler.register(with: registrar)
    }
    registerCustomChannels()
  }

  // Get the binary messenger from the FlutterViewController — more reliable
  // than going through the plugin registrar for custom non-plugin channels.
  //
  // `self.window?.rootViewController` isn't always attached the instant
  // `didInitializeImplicitFlutterEngine` fires, so this tries synchronously
  // first (closing the race entirely when it's already available) and
  // falls back to a short poll instead of a single deferred dispatch —
  // Dart-side code can otherwise reach the first video screen and call the
  // channel before a one-shot `DispatchQueue.main.async` has run.
  private func registerCustomChannels(retriesLeft: Int = 25) {
    guard let controller = self.window?.rootViewController as? FlutterViewController else {
      guard retriesLeft > 0 else { return }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
        self?.registerCustomChannels(retriesLeft: retriesLeft - 1)
      }
      return
    }

    let handler = PiPMethodChannel()
    handler.setup(with: controller.binaryMessenger)
    self.pipHandler = handler

    let airPlay = AirPlayHandler()
    airPlay.setup(with: controller.binaryMessenger)
    self.airPlayHandler = airPlay
  }
}

/// Backs the in-app notification inbox. iOS doesn't run Dart for a push it
/// shows while the app is in the background or closed, so those are collected
/// from Notification Center, and the icon badge is kept matching the inbox.
final class NotificationTrayHandler: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "labby/notification_tray",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(NotificationTrayHandler(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "takeDelivered":
      takeDelivered(result)
    case "setBadge":
      setBadge(call.arguments as? Int ?? 0)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Returns the FCM pushes in Notification Center, removing them from it so
  /// they're only collected once. Anything without a `gcm.message_id` is a
  /// foreground local notification, which the inbox already has.
  private func takeDelivered(_ result: @escaping FlutterResult) {
    let center = UNUserNotificationCenter.current()
    center.getDeliveredNotifications { notifications in
      let formatter = ISO8601DateFormatter()
      var taken: [[String: Any]] = []
      var identifiers: [String] = []

      for notification in notifications {
        let content = notification.request.content
        guard let messageId = content.userInfo["gcm.message_id"] as? String else { continue }
        taken.append([
          "id": messageId,
          "title": content.title,
          "body": content.body,
          "data": Self.customData(from: content.userInfo),
          "receivedAt": formatter.string(from: notification.date),
        ])
        identifiers.append(notification.request.identifier)
      }

      center.removeDeliveredNotifications(withIdentifiers: identifiers)
      DispatchQueue.main.async { result(taken) }
    }
  }

  /// The backend's `data` fields, without what APNs and FCM add around them.
  private static func customData(from userInfo: [AnyHashable: Any]) -> [String: String] {
    var data: [String: String] = [:]
    for (key, value) in userInfo {
      guard let key = key as? String, let value = value as? String,
        key != "aps", key != "fcm_options",
        !key.hasPrefix("gcm."), !key.hasPrefix("google.")
      else { continue }
      data[key] = value
    }
    return data
  }

  private func setBadge(_ count: Int) {
    if #available(iOS 16.0, *) {
      UNUserNotificationCenter.current().setBadgeCount(count)
    } else {
      UIApplication.shared.applicationIconBadgeNumber = count
    }
  }
}
