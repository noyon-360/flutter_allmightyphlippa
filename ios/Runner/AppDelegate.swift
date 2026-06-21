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

    // Get the binary messenger from the FlutterViewController — more reliable
    // than going through the plugin registrar for custom non-plugin channels.
    DispatchQueue.main.async { [weak self] in
      guard let self = self,
            let controller = self.window?.rootViewController as? FlutterViewController
      else { return }

      let handler = PiPMethodChannel()
      handler.setup(with: controller.binaryMessenger)
      self.pipHandler = handler

      let airPlay = AirPlayHandler()
      airPlay.setup(with: controller.binaryMessenger)
      self.airPlayHandler = airPlay
    }
  }
}
