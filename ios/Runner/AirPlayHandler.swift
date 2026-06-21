import AVKit
import Flutter
import UIKit

/// Presents the native iOS AirPlay route picker via a Flutter MethodChannel.
///
/// media_kit (MPV/Metal) and chewie/video_player do not expose a system route
/// button, so we drop an `AVRoutePickerView` into the key window and
/// programmatically trigger its internal button. This shows the same AirPlay
/// overlay the OS presents from Control Center, letting the user route playback
/// to an Apple TV or AirPlay 2 receiver.
class AirPlayHandler: NSObject {

    private weak var channel: FlutterMethodChannel?
    private var routePickerView: AVRoutePickerView?

    func setup(with messenger: FlutterBinaryMessenger) {
        let ch = FlutterMethodChannel(name: "com.almightyphlippa/airplay",
                                      binaryMessenger: messenger)
        self.channel = ch
        ch.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "showAirPlayPicker":
                self?.showAirPlayPicker(result: result)
            case "isAirPlayAvailable":
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func showAirPlayPicker(result: @escaping FlutterResult) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                result(false)
                return
            }

            let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
                         ?? UIApplication.shared.windows.first

            guard let window = keyWindow else {
                result(FlutterError(code: "NO_WINDOW",
                                    message: "No key window to attach AirPlay picker",
                                    details: nil))
                return
            }

            // Reuse a single hidden picker placed off-screen.
            let picker: AVRoutePickerView
            if let existing = self.routePickerView {
                picker = existing
            } else {
                let newPicker = AVRoutePickerView(frame: CGRect(x: -100, y: -100,
                                                                width: 44, height: 44))
                newPicker.prioritizesVideoDevices = true
                newPicker.alpha = 0.001
                window.addSubview(newPicker)
                self.routePickerView = newPicker
                picker = newPicker
            }

            // Trigger the picker's underlying UIButton to present the overlay.
            if let button = picker.subviews.compactMap({ $0 as? UIButton }).first {
                button.sendActions(for: .touchUpInside)
                result(true)
            } else {
                // Fallback: simulate a tap on the picker itself.
                for subview in picker.subviews {
                    if let control = subview as? UIControl {
                        control.sendActions(for: .touchUpInside)
                        result(true)
                        return
                    }
                }
                result(FlutterError(code: "NO_BUTTON",
                                    message: "Could not find AirPlay picker button",
                                    details: nil))
            }
        }
    }
}
