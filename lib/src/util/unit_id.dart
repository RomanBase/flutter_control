import 'dart:math';

class UnitId {
  static const az = 'abcdefghijklmnopqrstuvwxyz';
  static const aZ = 'aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ';
  static const azn = 'abcdefghijklmnopqrstuvwxyz0123456789';
  static const aZn = 'aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ0123456789';
  static const hex = '0123456789ABCDEF';

  static String cycleId(int index, String sequence) {
    if (index > sequence.length - 1) {
      final count = sequence.length;
      final num = index ~/ count;

      return cycleId(num - 1, sequence) + cycleId(index - count * num, sequence);
    }

    return sequence[index];
  }

  static String randomFromSequence(int count, String sequence) {
    final output = StringBuffer();

    final rnd = Random();

    for (int i = 0; i < count; i++) {
      output.write(sequence[rnd.nextInt(sequence.length)]);
    }

    return output.toString();
  }

  static String charId(int index, {int digitOffset: 0}) => cycleId(index + digitCycleOffset(digitOffset, az.length), az);

  static String nextId() {
    final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;

    return cycleId(stamp, aZn) + randomId(length: 4, includeNums: true);
  }

  static String randomId({int length: 8, bool includeNums: false, bool toUpper: false, bool toLower: false}) {
    String sequence = az;

    if (includeNums) {
      if (toUpper || toLower) {
        sequence = azn;
      } else {
        sequence = aZn;
      }
    } else {
      if (toUpper || toLower) {
        sequence = az;
      } else {
        sequence = aZ;
      }
    }

    final output = randomFromSequence(length, sequence);

    return toUpper ? output.toUpperCase() : output;
  }

  static int digitCycleOffset(int digits, int count) {
    if (digits < 2) {
      return 0;
    }

    if (digits < 3) {
      return count;
    }

    int max = 0;
    for (int i = 1; i < digits; i++) {
      max += pow(count, i);
    }

    return max;
  }
}
