import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:multicast_dns/multicast_dns.dart';

import 'cast_device.dart';

class CastDiscovery {
  static const _serviceType = '_googlecast._tcp';

  Future<List<CastDevice>> search({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final client = MDnsClient();
    final devices = <CastDevice>[];
    final seen = <String>{};
    final tasks = <Future<void>>[];
    final done = Completer<void>();
    Timer(timeout, () { if (!done.isCompleted) done.complete(); });

    try {
      await client.start();

      final sub = client
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer(_serviceType),
          )
          .listen((ptr) {
            if (seen.contains(ptr.domainName)) return;
            seen.add(ptr.domainName);
            tasks.add(_resolve(client, ptr, devices));
          });

      await done.future;
      await sub.cancel();
      await Future.wait(tasks, eagerError: false);
    } catch (e) {
      debugPrint('CastDiscovery error: $e');
    } finally {
      client.stop();
    }

    return devices;
  }

  Future<void> _resolve(
    MDnsClient client,
    PtrResourceRecord ptr,
    List<CastDevice> devices,
  ) async {
    try {
      final srv = await client
          .lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName))
          .first
          .timeout(const Duration(seconds: 2));

      final ip = await client
          .lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          )
          .first
          .timeout(const Duration(seconds: 2));

      final host = ip.address.address;
      if (devices.any((d) => d.host == host)) return;

      String name = ptr.domainName;
      final dot = name.indexOf('.');
      if (dot > 0) name = name.substring(0, dot);
      try {
        name = Uri.decodeComponent(name.replaceAll('+', ' '));
      } catch (_) {}

      devices.add(CastDevice(name: name, host: host, port: srv.port));
    } catch (_) {
      // Device unreachable or timed out — skip it
    }
  }
}
