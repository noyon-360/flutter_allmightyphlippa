import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/connectivity_service.dart';

/// Why a live stream failed to start, established by probing rather than
/// guessed from the player's error text.
///
/// mpv only ever reports `Failed to open <url>` — it carries no HTTP status
/// and no distinction between "your wifi is off", "the provider is down" and
/// "this channel is offline". Showing the viewer a generic "server may be
/// unavailable" for all three is what sends them to support with a problem
/// nobody on this side can fix. So when startup fails we re-request the same
/// URL ourselves and read the real answer off the wire.
enum StreamFailureCause {
  /// The device has no usable connection. Nothing else was probed.
  noInternet,

  /// The provider answered, with a server-side error (5xx). Their platform
  /// is broken; the app, the backend and the account are all fine.
  providerDown,

  /// The provider's host could not be reached at all, while our own API
  /// answered normally from the same device — so it is their outage, not
  /// the viewer's connection.
  providerUnreachable,

  /// The provider answered 401/403: the line is refused. Usually an expired
  /// subscription or too many simultaneous devices.
  providerRejected,

  /// The provider answered 404: this channel no longer exists for them.
  channelNotFound,

  /// The provider served the stream (2xx) but the player still could not
  /// render it. Not a provider outage — do not blame them for this.
  playbackFailed,

  /// The probe itself was inconclusive. Say nothing confident.
  unknown,
}

/// A verdict plus the copy to show for it.
@immutable
class StreamDiagnosis {
  const StreamDiagnosis({
    required this.cause,
    required this.message,
    this.detail,
  });

  final StreamFailureCause cause;

  /// Viewer-facing explanation.
  final String message;

  /// One short technical line ("Provider returned HTTP 512") shown under the
  /// message, so a support screenshot carries the evidence with it.
  final String? detail;

  /// Whether the evidence points at the provider strongly enough to tell the
  /// viewer so. Deliberately excludes [StreamFailureCause.playbackFailed] and
  /// [StreamFailureCause.unknown]: a stream we were served, or a probe that
  /// told us nothing, is not proof of anything on their end.
  bool get isProviderFault =>
      cause == StreamFailureCause.providerDown ||
      cause == StreamFailureCause.providerUnreachable ||
      cause == StreamFailureCause.providerRejected ||
      cause == StreamFailureCause.channelNotFound;
}

class StreamFailureDiagnosis {
  /// Matches what media_kit/mpv sends, so the probe is answered the same way
  /// the player was — some panels serve a different response to curl-ish UAs.
  static const _playerUserAgent = 'Lavf/60.3.100';

  static const _probeTimeout = Duration(seconds: 8);
  static const _backendProbeTimeout = Duration(seconds: 6);

  /// Probes [playUrl] and returns what actually went wrong.
  ///
  /// Only ever called on the failure path, so the extra request costs nothing
  /// during normal playback.
  static Future<StreamDiagnosis> diagnose({required String playUrl}) async {
    if (playUrl.isEmpty) {
      return const StreamDiagnosis(
        cause: StreamFailureCause.unknown,
        message: 'Failed to load stream.\nPlease try again.',
      );
    }

    if (!await ConnectivityService.instance.checkConnectivity()) {
      return const StreamDiagnosis(
        cause: StreamFailureCause.noInternet,
        message: 'No internet connection.\nCheck your network and try again.',
      );
    }

    final int? status = await _probeStatus(playUrl);
    debugPrint('Stream probe for $playUrl -> ${status ?? 'unreachable'}');

    if (status == null) {
      // The provider's host didn't answer. Decide whether that's them or us
      // by asking our own API from this same device.
      if (await _backendReachable()) {
        return const StreamDiagnosis(
          cause: StreamFailureCause.providerUnreachable,
          message:
              "Can't reach your TV provider's server.\n"
              'Their server is not responding. Your connection and the app '
              'are working normally.',
          detail: 'Provider host did not respond',
        );
      }
      return const StreamDiagnosis(
        cause: StreamFailureCause.noInternet,
        message: 'No internet connection.\nCheck your network and try again.',
      );
    }

    // 416 means the server rejected our range request — it is serving, and
    // that counts as reachable, not as an outage.
    if ((status >= 200 && status < 300) || status == 416) {
      return StreamDiagnosis(
        cause: StreamFailureCause.playbackFailed,
        message:
            "Your provider's server responded, but this channel could not be "
            'played.\nThe channel may be offline or in a format this device '
            'cannot play.',
        detail: 'Provider returned HTTP $status',
      );
    }

    if (status == 401 || status == 403) {
      return StreamDiagnosis(
        cause: StreamFailureCause.providerRejected,
        message:
            'Your TV provider refused this stream.\n'
            'Your subscription may have expired, or it is already in use on '
            'the maximum number of devices.',
        detail: 'Provider returned HTTP $status',
      );
    }

    if (status == 404 || status == 410) {
      return StreamDiagnosis(
        cause: StreamFailureCause.channelNotFound,
        message:
            'This channel is no longer available from your TV provider.\n'
            'Try another channel.',
        detail: 'Provider returned HTTP $status',
      );
    }

    if (status >= 500) {
      // Covers plain 500/502/503, Cloudflare's 520-527, and the 512 Xtream
      // panels return for "no source behind this stream".
      return StreamDiagnosis(
        cause: StreamFailureCause.providerDown,
        message:
            "Your TV provider's server is down.\n"
            'This is a problem on their side, not with the app. Please try '
            'again later or contact your provider.',
        detail: 'Provider returned HTTP $status',
      );
    }

    return StreamDiagnosis(
      cause: StreamFailureCause.unknown,
      message: 'Failed to load stream.\nPlease try again.',
      detail: 'Provider returned HTTP $status',
    );
  }

  /// Final HTTP status after redirects, or null if the host never answered.
  ///
  /// Uses a ranged GET rather than HEAD: Xtream panels routinely don't
  /// implement HEAD and would answer 405 to one, which would read as a
  /// provider error that isn't there.
  static Future<int?> _probeStatus(String url) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: _probeTimeout,
        receiveTimeout: _probeTimeout,
        sendTimeout: _probeTimeout,
        followRedirects: true,
        maxRedirects: 5,
        validateStatus: (_) => true,
        responseType: ResponseType.bytes,
        headers: {'User-Agent': _playerUserAgent, 'Range': 'bytes=0-1'},
      ),
    );
    try {
      final response = await dio.get<List<int>>(url);
      return response.statusCode;
    } on DioException catch (e) {
      // A redirect-limit or certificate failure still proves the host is up;
      // only genuine connect/timeout failures mean "no answer".
      return e.response?.statusCode;
    } catch (_) {
      return null;
    } finally {
      dio.close(force: true);
    }
  }

  /// Whether our own API answers from this device — the control that tells a
  /// provider outage apart from a dead connection.
  static Future<bool> _backendReachable() async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: _backendProbeTimeout,
        receiveTimeout: _backendProbeTimeout,
        validateStatus: (_) => true,
      ),
    );
    try {
      // Any response at all counts, including a 401 or 404 — it proves the
      // request left the device and came back.
      await dio.get<dynamic>(ApiConstants.baseDomain);
      return true;
    } catch (_) {
      return false;
    } finally {
      dio.close(force: true);
    }
  }
}
