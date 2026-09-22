import 'dart:convert';
import 'dart:typed_data';

/// The raw FIT record decoder.
///
/// This is a deliberately small reading of Garmin's FIT protocol: enough to
/// pull `file_id`, `workout` and `workout_step` out of a workout file, and
/// nothing more. It replaces `fit_dart_sdk`, which is the official port but
/// cannot be compiled for the web — it contains `int` literals larger than a
/// JavaScript number can hold, which is a compile error on both dart2js and
/// dart2wasm.
///
/// Structure, for anyone maintaining this:
///
/// * A 12- or 14-byte header, with the ASCII tag `.FIT` at offset 8.
/// * Then a stream of records. Each starts with one header byte that says
///   whether it defines a message layout or carries data for one, and which of
///   the 16 "local message types" it is talking about.
/// * A definition record declares the global message number and the field
///   number, size and base type of every field its data records will carry.
/// * A data record is then just those field values back to back, in order.
///
/// Every integer base type has a reserved "invalid" value — all bits set,
/// except for the signed types where it is the maximum positive value. Fields
/// holding it are reported as absent rather than as a number.
class FitDecodeException implements Exception {
  const FitDecodeException(this.message);

  final String message;

  @override
  String toString() => 'FitDecodeException: $message';
}

/// One decoded message: its global number and its fields, by field number.
class FitMessage {
  const FitMessage(this.globalMessageNumber, this.fields);

  final int globalMessageNumber;

  /// Field number to value. Absent and invalid fields are simply not here.
  final Map<int, Object?> fields;

  int? integer(int field) {
    final value = fields[field];
    if (value is int) return value;
    if (value is double) return value.round();
    return null;
  }

  String? string(int field) {
    final value = fields[field];
    return value is String && value.isNotEmpty ? value : null;
  }
}

/// True when [bytes] carries the `.FIT` signature.
///
/// Checked separately from a full decode so a caller can tell "not a FIT file"
/// apart from "a FIT file that is damaged".
bool hasFitSignature(Uint8List bytes) {
  if (bytes.length < 12) return false;
  const signature = [0x2E, 0x46, 0x49, 0x54]; // ".FIT"
  for (var i = 0; i < signature.length; i++) {
    if (bytes[8 + i] != signature[i]) return false;
  }
  return true;
}

/// Decodes every message in [bytes].
///
/// Throws [FitDecodeException] if the file is truncated, if its CRC does not
/// match, or if a data record arrives for a layout that was never defined.
List<FitMessage> decodeFitMessages(Uint8List bytes) {
  if (!hasFitSignature(bytes)) {
    throw const FitDecodeException('Missing .FIT signature');
  }

  final data = ByteData.sublistView(bytes);
  final headerSize = bytes[0];
  if (headerSize != 12 && headerSize != 14) {
    throw FitDecodeException('Unexpected header size $headerSize');
  }

  final dataSize = data.getUint32(4, Endian.little);
  final end = headerSize + dataSize;
  if (end > bytes.length) {
    throw FitDecodeException(
      'File declares $dataSize bytes of records but only '
      '${bytes.length - headerSize} are present',
    );
  }

  // A 14-byte header carries a CRC of the header itself; 0 means "not set".
  if (headerSize == 14) {
    final headerCrc = data.getUint16(12, Endian.little);
    if (headerCrc != 0 && _crc16(bytes, 0, 12) != headerCrc) {
      throw const FitDecodeException('Header CRC mismatch');
    }
  }

  // The file CRC covers the header and every record.
  if (bytes.length >= end + 2) {
    final fileCrc = data.getUint16(end, Endian.little);
    if (_crc16(bytes, 0, end) != fileCrc) {
      throw const FitDecodeException('File CRC mismatch');
    }
  } else {
    throw const FitDecodeException('File CRC is missing');
  }

  final definitions = <int, _MessageDefinition>{};
  final messages = <FitMessage>[];
  var offset = headerSize;

  while (offset < end) {
    final recordHeader = bytes[offset++];
    final isCompressedTimestamp = recordHeader & 0x80 != 0;

    final localType = isCompressedTimestamp
        ? (recordHeader >> 5) & 0x03
        : recordHeader & 0x0F;
    final isDefinition = !isCompressedTimestamp && recordHeader & 0x40 != 0;

    if (isDefinition) {
      final hasDeveloperFields = recordHeader & 0x20 != 0;
      final (definition, next) = _readDefinition(
        bytes,
        data,
        offset,
        hasDeveloperFields,
      );
      definitions[localType] = definition;
      offset = next;
      continue;
    }

    final definition = definitions[localType];
    if (definition == null) {
      throw FitDecodeException(
        'Data record for undefined local message type $localType',
      );
    }

    final (message, next) = _readData(bytes, data, offset, definition, end);
    messages.add(message);
    offset = next;
  }

  return messages;
}

class _FieldDefinition {
  const _FieldDefinition(this.number, this.size, this.baseType);

  final int number;
  final int size;
  final int baseType;

  /// Developer fields are read past but never surfaced; nothing here needs
  /// them, and skipping keeps the following fields correctly aligned.
  bool get isDeveloper => number < 0;
}

class _MessageDefinition {
  const _MessageDefinition(this.globalMessageNumber, this.endian, this.fields);

  final int globalMessageNumber;
  final Endian endian;
  final List<_FieldDefinition> fields;
}

(_MessageDefinition, int) _readDefinition(
  Uint8List bytes,
  ByteData data,
  int offset,
  bool hasDeveloperFields,
) {
  offset++; // reserved
  final endian = bytes[offset++] == 0 ? Endian.little : Endian.big;
  final globalMessageNumber = data.getUint16(offset, endian);
  offset += 2;

  final fieldCount = bytes[offset++];
  final fields = <_FieldDefinition>[];
  for (var i = 0; i < fieldCount; i++) {
    fields.add(
      _FieldDefinition(bytes[offset], bytes[offset + 1], bytes[offset + 2]),
    );
    offset += 3;
  }

  if (hasDeveloperFields) {
    final developerCount = bytes[offset++];
    for (var i = 0; i < developerCount; i++) {
      // Negative number marks it as one to read past and drop.
      fields.add(_FieldDefinition(-1 - i, bytes[offset + 1], 0x0D));
      offset += 3;
    }
  }

  return (_MessageDefinition(globalMessageNumber, endian, fields), offset);
}

(FitMessage, int) _readData(
  Uint8List bytes,
  ByteData data,
  int offset,
  _MessageDefinition definition,
  int end,
) {
  final fields = <int, Object?>{};

  for (final field in definition.fields) {
    if (offset + field.size > end) {
      throw const FitDecodeException('Record runs past the end of the file');
    }

    final value = _readField(bytes, data, offset, field, definition.endian);
    offset += field.size;

    if (value != null && !field.isDeveloper) {
      fields[field.number] = value;
    }
  }

  return (FitMessage(definition.globalMessageNumber, fields), offset);
}

/// Base type numbers, low five bits of the base-type byte.
const int _baseTypeString = 0x07;

/// Size in bytes of each base type, indexed by its number.
const List<int> _baseTypeSizes = [
  1, // enum
  1, // sint8
  1, // uint8
  2, // sint16
  2, // uint16
  4, // sint32
  4, // uint32
  1, // string
  4, // float32
  8, // float64
  1, // uint8z
  2, // uint16z
  4, // uint32z
  1, // byte
  8, // sint64
  8, // uint64
  8, // uint64z
];

Object? _readField(
  Uint8List bytes,
  ByteData data,
  int offset,
  _FieldDefinition field,
  Endian endian,
) {
  final baseType = field.baseType & 0x1F;

  if (baseType == _baseTypeString) {
    // Null-terminated UTF-8, padded to the declared size.
    final raw = bytes.sublist(offset, offset + field.size);
    final terminator = raw.indexOf(0);
    final text = utf8.decode(
      terminator == -1 ? raw : raw.sublist(0, terminator),
      allowMalformed: true,
    );
    return text.isEmpty ? null : text;
  }

  final size = baseType < _baseTypeSizes.length ? _baseTypeSizes[baseType] : 1;

  // An array field holds several values; nothing here needs one, and taking
  // the first keeps a scalar reader honest for the size-one case.
  if (field.size < size) return null;

  switch (baseType) {
    case 0x00: // enum
    case 0x02: // uint8
    case 0x0A: // uint8z
    case 0x0D: // byte
      final value = data.getUint8(offset);
      return value == 0xFF ? null : value;
    case 0x01: // sint8
      final value = data.getInt8(offset);
      return value == 0x7F ? null : value;
    case 0x03: // sint16
      final value = data.getInt16(offset, endian);
      return value == 0x7FFF ? null : value;
    case 0x04: // uint16
    case 0x0B: // uint16z
      final value = data.getUint16(offset, endian);
      return value == 0xFFFF ? null : value;
    case 0x05: // sint32
      final value = data.getInt32(offset, endian);
      return value == 0x7FFFFFFF ? null : value;
    case 0x06: // uint32
    case 0x0C: // uint32z
      final value = data.getUint32(offset, endian);
      return value == 0xFFFFFFFF ? null : value;
    case 0x08: // float32
      final value = data.getFloat32(offset, endian);
      return value.isNaN ? null : value;
    case 0x09: // float64
      final value = data.getFloat64(offset, endian);
      return value.isNaN ? null : value;
    default:
      // 64-bit integers: nothing in a workout file uses them, and they cannot
      // be represented exactly on the web anyway.
      return null;
  }
}

/// The CRC-16 Garmin specifies for FIT files.
int _crc16(Uint8List bytes, int start, int end) {
  const table = [
    0x0000,
    0xCC01,
    0xD801,
    0x1400,
    0xF001,
    0x3C00,
    0x2800,
    0xE401,
    0xA001,
    0x6C00,
    0x7800,
    0xB401,
    0x5000,
    0x9C01,
    0x8801,
    0x4400,
  ];

  var crc = 0;
  for (var i = start; i < end; i++) {
    final byte = bytes[i];

    var tmp = table[crc & 0x0F];
    crc = (crc >> 4) & 0x0FFF;
    crc = crc ^ tmp ^ table[byte & 0x0F];

    tmp = table[crc & 0x0F];
    crc = (crc >> 4) & 0x0FFF;
    crc = crc ^ tmp ^ table[(byte >> 4) & 0x0F];
  }
  return crc;
}
