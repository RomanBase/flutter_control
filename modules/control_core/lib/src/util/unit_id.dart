part of '../../core.dart';

class UnitId {
  const UnitId._();

  static const az = 'abcdefghijklmnopqrstuvwxyz';
  static const aZ = 'aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ';
  static const azn = 'abcdefghijklmnopqrstuvwxyz0123456789';
  static const aZn =
      'aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ0123456789';
  static const hex = '0123456789ABCDEF';

  static String get units => aZn;

  static String get instanceId => randomId(length: 4, sequence: aZn);

  static int instanceCounter = 0;

  static VoidCallback? onChanged;

  /// Cycles through given [sequence] and builds String based on given [index] number.
  ///
  /// For [UnitId.aZ] sequence results are:
  /// 0 - a
  /// 1 - b
  /// 26 - aa
  /// 27 - ab
  static String cycleId(int index, String sequence) {
    if (index > sequence.length - 1) {
      final count = sequence.length;
      final num = index ~/ count;

      return cycleId(num - 1, sequence) +
          cycleId(index - count * num, sequence);
    }

    return sequence[index];
  }

  /// Returns [UnitId.cycleId] of given [index].
  /// [UnitId.az] is used as input - so result is not case sensitive and without numbers.
  /// Set [digitOffset] to specify minimum length of final result.
  ///
  /// For [UnitId.aZ] sequence results are:
  /// 0 - a
  /// 1 - b
  /// 26 - aa
  /// 27 - ab
  static String charId(int index, {int digitOffset = 0}) =>
      cycleId(index + _digitCycleOffset(digitOffset, az.length), az);

  /// Returns [UnitId.cycleId] of current [microsecondsSinceEpoch] and adds [instanceId] and [instanceCounter] to the end of the String.
  /// [UnitId.units] is used as an input.
  static String nextId() {
    final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;

    final id = '${cycleId(stamp, units)}_${instanceId}_${++instanceCounter}';

    onChanged?.call();

    return id;
  }

  /// Returns random String with given [length] and settings.
  static String randomId({int length = 8, String sequence = az}) {
    final output = randomFromSequence(length, sequence);

    return output;
  }

  /// Returns random String with given [length] of chars form [sequence].
  static String randomFromSequence(int length, String sequence) {
    final output = StringBuffer();

    final rnd = math.Random();

    for (int i = 0; i < length; i++) {
      output.write(sequence[rnd.nextInt(sequence.length)]);
    }

    return output.toString();
  }

  /// Returns offset for given sequence length
  ///
  /// for 10 char sequence offsets are:
  /// (1)a - offset 0
  /// (2)aa - offset 10
  /// (3)aaa - offset 110
  /// (4)aaaa - offset 1110
  static int _digitCycleOffset(int digits, int count) {
    if (digits < 2) {
      return 0;
    }

    if (digits < 3) {
      return count;
    }

    int max = 0;
    for (int i = 1; i < digits; i++) {
      max += math.pow(count, i) as int;
    }

    return max;
  }
}
