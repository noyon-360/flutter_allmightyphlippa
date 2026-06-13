import AVKit
import Flutter

/// Handles Picture-in-Picture for iOS via a Flutter MethodChannel.
///
/// Strategy per content type:
///
///  • Chewie / video_player (Live TV):
///    Traverses the view hierarchy to find the existing AVPlayerLayer that
///    video_player places in a UIView. Passes it directly to
///    AVPictureInPictureController — zero latency.
///
///  • media_kit / Metal (Movies & Series):
///    Creates a tiny off-screen UIView with a new AVPlayer backed by the
///    stream URL. Waits for AVPlayerItem.status == .readyToPlay before
///    calling startPictureInPicture(), then removes the view when PiP ends.
class PiPMethodChannel: NSObject {

    private var pipController: AVPictureInPictureController?

    // Secondary player used for media_kit content (Metal has no AVPlayerLayer)
    private var secondaryPlayer: AVPlayer?
    private var secondaryPipView: UIView?
    private var statusObservation: NSKeyValueObservation?

    private weak var channel: FlutterMethodChannel?

    // MARK: - Setup

    func setup(with messenger: FlutterBinaryMessenger) {
        let ch = FlutterMethodChannel(name: "com.labbytv/pip",
                                      binaryMessenger: messenger)
        self.channel = ch
        ch.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "isPiPAvailable":
                result(AVPictureInPictureController.isPictureInPictureSupported())

            case "enablePiP":
                let args = call.arguments as? [String: Any]
                let url      = args?["url"]      as? String
                let position = args?["position"] as? Double ?? 0.0
                self?.enablePiP(videoUrl: url, position: position, result: result)

            case "disablePiP":
                self?.pipController?.stopPictureInPicture()
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // MARK: - Enable PiP

    private func enablePiP(videoUrl: String?,
                            position: Double,
                            result: @escaping FlutterResult) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "PiP is not supported on this device",
                                details: nil))
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 1. Try existing AVPlayerLayer from Chewie / video_player
            let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
                         ?? UIApplication.shared.windows.first

            if let window = keyWindow,
               let existingLayer = self.findAVPlayerLayer(in: window),
               let player = existingLayer.player,
               player.currentItem != nil {
                self.createPiPController(with: existingLayer, result: result)
                return
            }

            // 2. Fallback: secondary AVPlayer for media_kit (Metal) content
            guard let urlString = videoUrl, let url = URL(string: urlString) else {
                result(FlutterError(code: "NO_URL",
                                    message: "No AVPlayerLayer found and no URL supplied",
                                    details: nil))
                return
            }

            self.startSecondaryPlayerPiP(url: url,
                                         position: position,
                                         result: result)
        }
    }

    // MARK: - Secondary player (media_kit fallback)

    private func startSecondaryPlayerPiP(url: URL,
                                          position: Double,
                                          result: @escaping FlutterResult) {
        tearDownSecondaryPlayer()

        let playerItem = AVPlayerItem(url: url)
        let player     = AVPlayer(playerItem: playerItem)
        self.secondaryPlayer = player

        // A tiny UIView — NOT hidden (alpha ~0 keeps it invisible but valid for PiP)
        let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
                     ?? UIApplication.shared.windows.first

        let pipView = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
        pipView.alpha = 0.01
        keyWindow?.addSubview(pipView)
        self.secondaryPipView = pipView

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = pipView.bounds
        pipView.layer.addSublayer(playerLayer)

        // Observe player item status — wait for readyToPlay before starting PiP
        statusObservation?.invalidate()
        statusObservation = playerItem.observe(\.status,
                                               options: [.new]) { [weak self, weak player, weak playerItem] item, _ in
            guard let self = self, let player = player else { return }
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    self.statusObservation?.invalidate()
                    if position > 0 {
                        player.seek(to: CMTime(seconds: position,
                                               preferredTimescale: 600)) { [weak self] _ in
                            player.play()
                            self?.createPiPController(with: playerLayer, result: result)
                        }
                    } else {
                        player.play()
                        self.createPiPController(with: playerLayer, result: result)
                    }
                case .failed:
                    self.statusObservation?.invalidate()
                    let msg = playerItem?.error?.localizedDescription ?? "Unknown error"
                    self.tearDownSecondaryPlayer()
                    result(FlutterError(code: "PLAYER_FAILED", message: msg, details: nil))
                default:
                    break
                }
            }
        }

        // Start buffering
        player.play()

        // Safety timeout: try to start PiP anyway after 6 s even if not readyToPlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self, weak player] in
            guard let self = self,
                  self.secondaryPlayer === player,
                  self.pipController == nil else { return }
            self.statusObservation?.invalidate()
            player?.play()
            self.createPiPController(with: playerLayer, result: result)
        }
    }

    // MARK: - Create & start PiP controller

    private func createPiPController(with playerLayer: AVPlayerLayer,
                                      result: @escaping FlutterResult) {
        let pip = AVPictureInPictureController(playerLayer: playerLayer)
        pip?.delegate = self
        self.pipController = pip

        // 0.5 s allows the controller to finish initialising before we start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            pip?.startPictureInPicture()
            result(true)
        }
    }

    // MARK: - Cleanup

    private func tearDownSecondaryPlayer() {
        statusObservation?.invalidate()
        statusObservation = nil
        secondaryPlayer?.pause()
        secondaryPlayer = nil
        secondaryPipView?.removeFromSuperview()
        secondaryPipView = nil
    }

    // MARK: - View-hierarchy traversal

    private func findAVPlayerLayer(in view: UIView) -> AVPlayerLayer? {
        if let found = findInLayer(view.layer) { return found }
        for subview in view.subviews {
            if let found = findAVPlayerLayer(in: subview) { return found }
        }
        return nil
    }

    private func findInLayer(_ layer: CALayer) -> AVPlayerLayer? {
        if let pl = layer as? AVPlayerLayer { return pl }
        for sub in layer.sublayers ?? [] {
            if let found = findInLayer(sub) { return found }
        }
        return nil
    }
}

// MARK: - AVPictureInPictureControllerDelegate

extension PiPMethodChannel: AVPictureInPictureControllerDelegate {

    func pictureInPictureControllerWillStartPictureInPicture(
        _ controller: AVPictureInPictureController
    ) {
        channel?.invokeMethod("onPiPStarted", arguments: nil)
    }

    func pictureInPictureControllerDidStopPictureInPicture(
        _ controller: AVPictureInPictureController
    ) {
        tearDownSecondaryPlayer()
        pipController = nil
        channel?.invokeMethod("onPiPStopped", arguments: nil)
    }

    func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        tearDownSecondaryPlayer()
        pipController = nil
        channel?.invokeMethod("onPiPFailed", arguments: error.localizedDescription)
    }
}
