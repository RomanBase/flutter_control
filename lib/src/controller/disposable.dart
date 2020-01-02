import 'package:flutter_control/core.dart';

/// Standard disposable implementation.
abstract class Disposable {
  /// Used to clear and dispose object.
  /// After this method call is object typically unusable and ready for GC.
  /// Can be called multiple times!
  void dispose();
}

extension DisposableExt on Disposable {
  dynamic disposeWith(Disposer disposer, {VoidCallback onDispose, bool forceDispose: false}) {
    disposer.addToDispose(this, onDispose: onDispose, forceDispose: forceDispose);

    return this;
  }
}

mixin DisposeHandler implements Disposable {
  bool get preventDispose => false;

  bool get preferSoftDispose => false;

  void requestDispose() {
    if (preventDispose) {
      return;
    }

    if (preferSoftDispose) {
      softDispose();
    } else {
      dispose();
    }
  }

  void softDispose() {}

  @override
  void dispose() {
    if (this is Disposer) {
      (this as Disposer).executeDispose();
    }
  }
}

class DisposableItem implements Disposable {
  final Disposable disposable;
  final VoidCallback onDispose;
  final forceDispose;

  DisposableItem(this.disposable, this.onDispose, this.forceDispose);

  @override
  void dispose() {
    if (onDispose != null) {
      onDispose();
    }

    if (!forceDispose && disposable is DisposeHandler) {
      (disposable as DisposeHandler).requestDispose();
    } else {
      disposable.dispose();
    }
  }
}

mixin Disposer {
  List<DisposableItem> _disposables;

  void autoDispose(List<Disposable> disposables) {
    if (_disposables == null) {
      _disposables = List<DisposableItem>();
    }

    disposables.forEach((item) => _disposables.add(DisposableItem(item, null, false)));
  }

  void addToDispose(Disposable disposable, {VoidCallback onDispose, bool forceDispose: false}) {
    if (_disposables == null) {
      _disposables = List<DisposableItem>();
    }

    _disposables.add(DisposableItem(disposable, onDispose, forceDispose));
  }

  void removeFromDispose(Disposable disposable) {
    _disposables?.remove(disposable);
  }

  void executeDispose() {
    if (_disposables != null) {
      _disposables.forEach((item) {});
      _disposables.clear();
      _disposables = null;
    }
  }
}
