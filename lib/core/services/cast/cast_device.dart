class CastDevice {
  final String name;
  final String host;
  final int port;

  const CastDevice({required this.name, required this.host, required this.port});

  @override
  String toString() => 'CastDevice($name @ $host:$port)';

  @override
  bool operator ==(Object other) =>
      other is CastDevice && other.host == host && other.port == port;

  @override
  int get hashCode => Object.hash(host, port);
}
