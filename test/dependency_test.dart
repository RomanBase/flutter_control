import 'package:control_core/core.dart';
import 'package:flutter_test/flutter_test.dart';

final c = Control.newFactory();

class A {}

class B {
  final A ref;

  const B(this.ref); //Dependency Injection
}

class C {
  A get ref => c.get<A>()!; // Property Injection
}

void main() {
  test('dependency', () {
    c.initialize(
      factories: {
        A: (_) => A(),
        B: (_) => B(c<A>()!),
      },
    );

    expect(c<A>(), isNotNull);
    expect(c<B>()?.ref, isNotNull);
    expect(C().ref, isNotNull);
  });
}
