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
/// Use [requestDispose] to handle dispose execution.
/// [preventDispose] - do nothing. Final [dispose] must be called manually.
/// [preferSoftDispose] - executes [softDispose]. Useful for items in list and objects stored in [ControlFactory]. Final [dispose] must be handled manually.
///
/// [dispose] can be still called directly.
mixin DisposeHandler implements Disposable {
  /// [requestDispose] do nothing if set. Final [dispose] must be handled manually.
  bool preventDispose = false;

  /// [requestDispose] will execute [softDispose]. Useful for items in list and objects store in [ControlFactory]. Final [dispose] must be handled manually.
  bool preferSoftDispose = false;

  /// Executes dispose based on [preventDispose] and [preferSoftDispose] settings.
  /// [parent] - actual object that requesting dispose.
  void requestDispose([dynamic parent]) {
    if (preventDispose) {
      return;
    }

    if (preferSoftDispose) {
      softDispose();
    } else {
      dispose();
    }
  }

  /// Just soft dispose - stop loading / subscriptions etc.
  /// For example called when List item hides and is recycled.
  /// Also useful when Control is used with multiple Widgets to prevent final [dispose].
  void softDispose() {}

  @override
  void dispose() {
    softDispose();
  }
}

/// Mixin class for [DisposeHandler] - mostly used with [LazyControl] and [ControlModel].
/// Counts references by [hashCode]. References must be added/removed manually.
///
/// When there is 1 or more reference then [preferSoftDispose] is set.
mixin ReferenceCounter on DisposeHandler {
  /// List of references.
  final _references = new List<int>();

  int get referenceCount => _references.length;

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

  @override
  void requestDispose([parent]) {
    if (parent != null) {
      removeReference(parent);
    }

    super.requestDispose(parent);
  }

  /// Clears all references.
  /// So [preferSoftDispose] is not set.
  void clear() => _references.clear();

  @override
  void dispose() {
    super.dispose();

    clear();
  }
}

class DisposableToken implements Disposable {
  dynamic parent;
  dynamic data;

  VoidCallback onFinish;
  VoidCallback onCancel;
  VoidCallback onDispose;

  bool _isActive = true;

  bool get isActive => _isActive;

  bool _isFinished = false;

  bool get isFinished => _isFinished;

  final bool autoDispose;

  DisposableToken({
    this.parent,
    this.data,
    this.autoDispose: true,
  });

  void finish() {
    _isFinished = true;
    onFinish?.call();

    if (autoDispose) {
      dispose();
    }
  }

  void cancel() {
    _isActive = false;
    onCancel?.call();

    if (autoDispose) {
      dispose();
    }
  }

  @override
  void dispose() {
    _isActive = false;

    onDispose?.call();
    onDispose = null;
    onFinish = null;
    onCancel = null;
  }
}
