import 'dart:convert';
import 'dart:typed_data';

/// Encodes a CastMessage protobuf with a 4-byte big-endian length prefix.
Uint8List encodeCastMessage({
  required String sourceId,
  required String destinationId,
  required String namespace,
  required String payloadUtf8,
}) {
  final buf = BytesBuilder();

  _writeVarintField(buf, 1, 0); // protocol_version = CASTV2_1_0 (0)
  _writeBytesField(buf, 2, utf8.encode(sourceId));
  _writeBytesField(buf, 3, utf8.encode(destinationId));
  _writeBytesField(buf, 4, utf8.encode(namespace));
  _writeVarintField(buf, 5, 0); // payload_type = STRING (0)
  _writeBytesField(buf, 7, utf8.encode(payloadUtf8));

  final proto = buf.toBytes();
  final header = ByteData(4)..setUint32(0, proto.length, Endian.big);

  final out = BytesBuilder();
  out.add(header.buffer.asUint8List());
  out.add(proto);
  return out.toBytes();
}

/// Decodes a CastMessage protobuf, returns the JSON payload merged with the namespace.
Map<String, dynamic>? decodeCastMessage(Uint8List data) {
  int offset = 0;
  String? namespace;
  String? payloadUtf8;

  while (offset < data.length) {
    final tagRead = _readVarint(data, offset);
    if (tagRead == null) break;
    offset = tagRead.$2;

    final fieldNum = tagRead.$1 >> 3;
    final wireType = tagRead.$1 & 0x7;

    if (wireType == 0) {
      final val = _readVarint(data, offset);
      if (val == null) break;
      offset = val.$2;
    } else if (wireType == 2) {
      final lenRead = _readVarint(data, offset);
      if (lenRead == null) break;
      offset = lenRead.$2;
      final length = lenRead.$1;
      if (offset + length > data.length) break;
      final bytes = data.sublist(offset, offset + length);
      offset += length;
      if (fieldNum == 4) {
        namespace = utf8.decode(bytes, allowMalformed: true);
      } else if (fieldNum == 7) {
        payloadUtf8 = utf8.decode(bytes, allowMalformed: true);
      }
    } else {
      break;
    }
  }

  if (payloadUtf8 == null) return null;
  try {
    final json = jsonDecode(payloadUtf8) as Map<String, dynamic>;
    if (namespace != null) json['_namespace'] = namespace;
    return json;
  } catch (_) {
    return null;
  }
}

void _writeVarintField(BytesBuilder buf, int fieldNum, int value) {
  _writeVarintRaw(buf, (fieldNum << 3) | 0);
  _writeVarintRaw(buf, value);
}

void _writeBytesField(BytesBuilder buf, int fieldNum, List<int> bytes) {
  _writeVarintRaw(buf, (fieldNum << 3) | 2);
  _writeVarintRaw(buf, bytes.length);
  buf.add(bytes);
}

void _writeVarintRaw(BytesBuilder buf, int value) {
  if (value == 0) {
    buf.addByte(0);
    return;
  }
  while (value > 0) {
    final byte = value & 0x7F;
    value >>= 7;
    buf.addByte(value > 0 ? byte | 0x80 : byte);
  }
}

(int, int)? _readVarint(Uint8List data, int offset) {
  int value = 0;
  int shift = 0;
  while (offset < data.length) {
    final byte = data[offset++];
    value |= (byte & 0x7F) << shift;
    if ((byte & 0x80) == 0) return (value, offset);
    shift += 7;
    if (shift >= 64) return null;
  }
  return null;
}
