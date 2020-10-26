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

  static void disposeOf(dynamic object, dynamic parent) {
    if (object is DisposeHandler) {
      object.requestDispose(parent);
    } else if (object is Disposable) {
      object.dispose();
    }
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

/// {@template disposable-client}
/// Propagates `thread` notifications that can be canceled.
///
/// For example can be used to represent Image upload Stream that can be canceled.
/// {@end-template}
class DisposableClientBase implements Disposable {
  /// Parent of this disposer.
  final dynamic parent;

  /// Callback when token is finished and [finish] called.
  VoidCallback onFinish;

  /// Callback when token is canceled and [finish] called.
  VoidCallback onCancel;

  /// Callback when token is disposed and [finish] called.
  VoidCallback onDispose;

  /// Propagates `thread` notifications with possibility to cancel operations.
  /// [parent] - Parent object of this client.
  DisposableClientBase({this.parent});

  /// Finishes this token and notifies [onFinish] listener.
  void finish() => onFinish?.call();

  /// Cancels this token and notifies [onCancel] listener.
  void cancel() => onCancel?.call();

  @override
  void dispose() {
    onDispose?.call();
  }
}

/// {@macro disposable-client}
/// [DisposableClient] is used at `Client` side and [DisposableToken] at `User` side.
class DisposableClient extends DisposableClientBase {
  /// Propagates `thread` notifications with possibility to cancel operations.
  /// [parent] - Parent object of this client.
  DisposableClient({dynamic parent}) : super(parent: parent);

  /// Creates [DisposableToken] that can be used by `Client`.
  DisposableToken asToken({dynamic data}) => DisposableToken(this, data: data);
}

/// {@macro disposable-client}
/// [DisposableClient] is used at `Client` side and [DisposableToken] at `User` side.
class DisposableToken extends DisposableClientBase {
  final DisposableClientBase _client;

  @override
  dynamic get parent => _client.parent;

  /// Additional data of this token.
  dynamic data;

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
  /// [_client] - Parent client of this token.
  /// [data] - Initial token data.
  DisposableToken(
    this._client, {
    this.data,
  }) : assert(_client != null);

  /// Propagates `thread` notifications with possibility to cancel operations.
  ///
  /// [parent] - Parent object of this token.
  /// [data] - Initial token data.
  /// [onCancel] - Client event that is called when token is canceled.
  /// [onFinish] - Client event that is called when token is finished.
  /// [onDispose] - Client event that is called when token is disposed.
  factory DisposableToken.client({
    dynamic parent,
    VoidCallback onCancel,
    VoidCallback onFinish,
    VoidCallback onDispose,
    dynamic data,
  }) =>
      DisposableToken(
        DisposableClientBase(
          parent: parent,
        )
          ..onCancel = onCancel
          ..onFinish = onFinish
          ..onDispose = onDispose,
        data: data,
      );

  /// Finishes this token and notifies [onFinish] listener.
  /// Typically called by API.
  @override
  void finish([bool autoDispose = true]) {
    super.finish();

    _isFinished = true;
    _client.onFinish?.call();
    onFinish?.call();

    if (autoDispose) {
      dispose();
    }
  }

  /// Cancels this token and notifies [onCancel] listener.
  /// Typically called by Client.
  @override
  void cancel([bool autoDispose = true]) {
    super.cancel();

    _isActive = false;
    onCancel?.call();

    if (autoDispose) {
      dispose();
    }
  }

  @override
  void dispose() {
    super.dispose();

    _isActive = false;

    onDispose?.call();
    onDispose = null;
    onFinish = null;
    onCancel = null;
  }
}
