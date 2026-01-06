import 'package:flutter_control/control.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generic', () {
    final g1 = Generic();
    final g2 = Generic((value) {});

    expect('${g1.generic}', 'dynamic');
    expect('${g2.generic}', 'Object?');
  });
}

class Generic<T> extends BaseModel {
  final Function(T)? callback;

  Generic([this.callback]);

  Type get generic => T;
}
