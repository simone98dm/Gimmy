import 'dart:convert';
import 'dart:typed_data';

/// The reference workout every import, execution and golden test runs on,
/// encoded as a real FIT file in memory.
///
/// 13 stored steps, 3 repeat blocks (one of them a two-exercise block), which
/// expand to [sampleFitStepCount] flat steps and [sampleFitTimerSeconds] of
/// timers. The parser tests assert those numbers.
const sampleFitFilename = 'full_body_sample.fit';
const sampleFitPlanName = 'Full Body Sample';
const sampleFitStepCount = 22;

/// 300 + 3×60 + 3×45 + 2×(30+30) + 300 + 180.
const sampleFitTimerSeconds = 1215;

/// 3 Squat steps × 10 reps + 6 Row steps × 12 reps.
const sampleFitTotalReps = 102;

const sampleFitSquatNotes = 'Chest up, knees over toes — full depth.';

Uint8List sampleFitBytes() => encodeFitWorkout(
  name: sampleFitPlanName,
  steps: const [
    FitStep.time(0, 'Warm-up bike', seconds: 300, intensity: _warmup),
    FitStep.reps(1, 'Squat', reps: 10, notes: sampleFitSquatNotes),
    FitStep.time(2, 'Rest', seconds: 60, intensity: _rest),
    FitStep.repeat(3, from: 1, count: 3),
    FitStep.reps(4, 'Row left', reps: 12, notes: 'Brace on the bench.'),
    FitStep.reps(5, 'Row right', reps: 12),
    FitStep.time(6, 'Rest', seconds: 45, intensity: _rest),
    FitStep.repeat(7, from: 4, count: 3),
    FitStep.time(8, 'Plank', seconds: 30),
    FitStep.time(9, 'Rest', seconds: 30, intensity: _rest),
    FitStep.repeat(10, from: 8, count: 2),
    FitStep.time(11, 'Cool-down walk', seconds: 300, intensity: _cooldown),
    FitStep.time(12, 'Stretching', seconds: 180, intensity: _cooldown),
  ],
);

const _active = 0;
const _rest = 1;
const _warmup = 2;
const _cooldown = 3;

/// One `workout_step` message.
class FitStep {
  const FitStep.time(
    this.index,
    this.name, {
    required int seconds,
    this.intensity = _active,
    this.notes,
  }) : durationType = 0,
       durationValue = seconds * 1000,
       targetValue = null;

  const FitStep.reps(
    this.index,
    this.name, {
    required int reps,
    this.intensity = _active,
    this.notes,
  }) : durationType = 29,
       durationValue = reps,
       targetValue = null;

  /// Jumps back to message index [from]; the block runs [count] times total.
  const FitStep.repeat(this.index, {required int from, required int count})
    : name = null,
      intensity = null,
      notes = null,
      durationType = 6,
      durationValue = from,
      targetValue = count;

  final int index;
  final String? name;
  final int? intensity;
  final String? notes;
  final int durationType;
  final int durationValue;
  final int? targetValue;
}

/// Encodes a minimal, valid FIT workout file: header with CRC, `file_id`,
/// `workout`, the steps, and the trailing file CRC.
Uint8List encodeFitWorkout({
  required String name,
  required List<FitStep> steps,
}) {
  final records = BytesBuilder()
    // file_id, local 0: type (enum) = 5, workout.
    ..add(_definition(0, globalNumber: 0, fields: [(0, 1, 0x00)]))
    ..add([0x00, 5])
    // workout, local 1: wkt_name (string).
    ..add(_definition(1, globalNumber: 26, fields: [(8, _nameSize, 0x07)]))
    ..add([0x01, ..._string(name, _nameSize)])
    // workout_step, local 2.
    ..add(
      _definition(
        2,
        globalNumber: 27,
        fields: [
          (254, 2, 0x84), // message_index, uint16
          (0, _nameSize, 0x07), // wkt_step_name
          (1, 1, 0x00), // duration_type, enum
          (2, 4, 0x86), // duration_value, uint32
          (4, 4, 0x86), // target_value, uint32
          (7, 1, 0x00), // intensity, enum
          (8, _notesSize, 0x07), // notes
        ],
      ),
    );

  for (final step in steps) {
    records
      ..add([0x02])
      ..add(_uint16(step.index))
      ..add(_string(step.name, _nameSize))
      ..add([step.durationType])
      ..add(_uint32(step.durationValue))
      ..add(_uint32(step.targetValue ?? 0xFFFFFFFF))
      ..add([step.intensity ?? 0xFF])
      ..add(_string(step.notes, _notesSize));
  }

  final body = records.toBytes();
  final header = Uint8List(14)
    // Header size, protocol 2.0, profile 21.32.
    ..[0] = 14
    ..[1] = 0x20
    ..setAll(2, _uint16(2132))
    ..setAll(4, _uint32(body.length))
    ..setAll(8, ascii.encode('.FIT'));
  header.setAll(12, _uint16(fitCrc16(header.sublist(0, 12))));

  final file = BytesBuilder()
    ..add(header)
    ..add(body);
  final withoutCrc = file.toBytes();
  return (BytesBuilder()
        ..add(withoutCrc)
        ..add(_uint16(fitCrc16(withoutCrc))))
      .toBytes();
}

const _nameSize = 32;
const _notesSize = 64;

List<int> _definition(
  int localType, {
  required int globalNumber,
  required List<(int, int, int)> fields,
}) => [
  0x40 | localType,
  0, // reserved
  0, // little-endian
  ..._uint16(globalNumber),
  fields.length,
  for (final (number, size, baseType) in fields) ...[number, size, baseType],
];

List<int> _uint16(int value) =>
    (ByteData(2)..setUint16(0, value, Endian.little)).buffer.asUint8List();

List<int> _uint32(int value) =>
    (ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List();

/// Null-terminated UTF-8, zero-padded to [size]. All zeros means "absent".
List<int> _string(String? text, int size) {
  final encoded = utf8.encode(text ?? '');
  assert(encoded.length < size, '"$text" does not fit in $size bytes');
  return [...encoded, ...List.filled(size - encoded.length, 0)];
}

/// Garmin's FIT CRC-16, written out independently of the decoder's so the
/// fixture cannot share a bug with the code it tests.
int fitCrc16(List<int> bytes) {
  var crc = 0;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = crc & 1 != 0 ? (crc >> 1) ^ 0xA001 : crc >> 1;
    }
  }
  return crc;
}
