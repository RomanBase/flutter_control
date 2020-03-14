import 'package:flutter_control/core.dart';

/// Standard dispose implementation.
abstract class Disposable {
  /// Used to clear and dispose object.
  /// After this method call is object typically unusable and ready for GC.
  /// Can be called multiple times!
  void dispose();
}

/// Handles dispose in multiple ways.
///
/// Use [DisposeHandler.requestDispose] to handle dispose way:
/// [preventDispose] - do nothing. Final [dispose] must be handled manually.
/// [preferSoftDispose] - executes [softDispose]. Useful for items in list and objects store in [ControlFactory]. Final [dispose] must be handled manually.
///
/// [dispose] can be still called directly.
mixin DisposeHandler implements Disposable {

  /// [requestDispose] do nothing if set. Final [dispose] must be handled manually.
  bool preventDispose = false;

  /// [requestDispose] will execute [softDispose]. Useful for items in list and objects store in [ControlFactory]. Final [dispose] must be handled manually.
  bool preferSoftDispose = false;

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

///TODO: revalidate purpose
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

///TODO: revalidate purpose
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

///TODO: revalidate purpose
extension DisposableExt on Disposable {
  dynamic disposeWith(Disposer disposer, {VoidCallback onDispose, bool forceDispose: false}) {
    disposer.addToDispose(this, onDispose: onDispose, forceDispose: forceDispose);

    return this;
  }
}

/// Mixin class for [DisposeHandler] - mostly used with [LazyControl] and [ControlModel].
/// Counts references by [hashCode]. References must be added/removed manually.
///
/// When there is 1 or more reference then [preferSoftDispose] is set.
mixin ReferenceCounter on DisposeHandler {
  /// List of references.
  final _references = new List<int>();

  @override
  bool get preferSoftDispose => _references.isNotEmpty;

  /// Reference is passed by given [object], but only [Object.hashCode] is store, to prevent 'shady' two way referencing (so native GC will not be affected).
  /// When there is 1 or more reference then [preferSoftDispose] is set.
  void addReference(Object object) {
    if (_references.contains(object.hashCode)) {
      return;
    }

    _references.add(object.hashCode);
  }

  /// Removes reference of given [object].
  /// When there is 1 or more reference then [preferSoftDispose] is set.
  void removeReference(Object object) => _references.remove(object.hashCode);

  /// Clears all references.
  /// So [preferSoftDispose] is not set.
  void clear() => _references.clear();

  @override
  void dispose() {
    super.dispose();

    clear();
  }
}
