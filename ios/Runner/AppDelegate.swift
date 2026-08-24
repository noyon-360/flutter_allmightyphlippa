import Flutter
import UIKit
import AVFoundation

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
