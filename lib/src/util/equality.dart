class Equality {
  static bool of(dynamic a, dynamic b) => a == b;

  static bool valid(dynamic value) => value is bool ? value : value != null;

  static bool greater(num? a, num? b) {
    if (a == null || b == null) {
      return false;
    }

    return a > b;
  }

  static bool greaterOrEqual(num? a, num? b) {
    if (a == null || b == null) {
      return false;
    }

    return a >= b;
  }

  static bool less(num? a, num? b) {
    if (a == null || b == null) {
      return false;
    }

    return a < b;
  }

  static bool lessOrEqual(num? a, num? b) {
    if (a == null || b == null) {
      return false;
    }

    return a <= b;
  }
}
