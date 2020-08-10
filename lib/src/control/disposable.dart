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

//TODO: Client vs. System events..
/// Propagates `thread` notifications that can be canceled.
///
/// For example can be used to represent Image upload Stream that can be canceled.
class DisposableToken implements Disposable {
  /// Parent of this token.
  final dynamic parent;

  /// Additional data of this token.
  dynamic data;

  /// Callback when token is finished and [finish] called.
  /// Typically used by Client.
  VoidCallback onFinish;

  /// Callback when token is canceled and [finish] called.
  /// Typically used by System.
  VoidCallback onCancel;

  /// Callback when token is disposed and [finish] called.
  /// Typically used by System.
  VoidCallback onDispose;

  /// Checks if token is active.
  bool _isActive = true;

  /// Checks if [cancel] or [dispose] hasn't been executed.
  bool get isActive => _isActive;

  /// Checks if token is finalized.
  bool _isFinished = false;

  /// Checks if [finish] has been executed.
  bool get isFinished => _isFinished;

  /// Propagates `thread` notifications with possibility to cancel operations.
  ///
  /// [parent] - Parent object of this token.
  /// [data] - Initial token data.
  DisposableToken({
    this.parent,
    this.data,
  });

  /// Finishes this token an notifies [onFinish] listener.
  /// Typically called by API.
  void finish([bool autoDispose = true]) {
    _isFinished = true;
    onFinish?.call();

    if (autoDispose) {
      dispose();
    }
  }

  /// Cancels this token an notifies [onCancel] listener.
  /// Typically called by Client.
  void cancel([bool autoDispose = true]) {
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
