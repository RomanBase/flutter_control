part of '../../core.dart';

/// Dump marker used to mark object for dispose.
typedef DisposeMarker = Function();

/// Mark Object as Disposable to let other know, that this Object can hold some resources that needs to be to invalidated and cleared.
mixin Disposable {
  /// Used to clear and dispose object.
  /// Unsubscribe and close all sources. Prepare object for GC.
  /// Can be called multiple times!
  void dispose();
}

extension DisposableExt on Disposable {
  /// Register for dispose with given [observer].
  void disposeWith(DisposeObserver observer) => observer.registerDispose(this);
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

  /// [requestDispose] will execute [softDispose]. Useful for items in list and objects stored in [ControlFactory]. Final [dispose] must be handled manually.
  bool preferSoftDispose = false;

  /// Executes dispose based on [preventDispose] and [preferSoftDispose] settings.
  /// [sender] - actual object that requesting dispose - can be null.
  void requestDispose([Object? sender]) {
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
  /// Also useful when Control is used with multiple Widgets to prevent fatal [dispose].
  void softDispose() {}

  @override
  void dispose() {
    softDispose();
  }

  /// Util function to properly request dispose of given [object].
  static void disposeOf(Object? object, Object? sender) {
    if (object is DisposeHandler) {
      object.requestDispose(sender);
    } else if (object is Disposable) {
      object.dispose();
    }
  }
}

/// Mixin class for [DisposeHandler] - mostly used with [LazyControl] and/or to control reference within Widget Tree.
/// Counts references by [hashCode]. References must be added/removed manually.
///
/// When there is 1 or more reference then [preferSoftDispose] is set.
/// Counter don't hold 'ref' to other objects, just their hashes.
mixin ReferenceCounter on DisposeHandler {
  /// List of references.
  final _references = <int>[];

  /// Number of registered references.
  int get referenceCount => _references.length;

  @override
  bool get preferSoftDispose => _references.isNotEmpty;

  /// Reference is passed by given [sender], but only [Object.hashCode] is store, to prevent 'shady' two way referencing (so native GC will not be affected).
  /// When there is 1 or more reference then [preferSoftDispose] is set.
  void addReference(Object sender) {
    if (_references.contains(sender.hashCode)) {
      return;
    }

    _references.add(sender.hashCode);
  }

  /// Removes reference of given [sender].
  /// When there is 1 or more reference then [preferSoftDispose] is set.
  void removeReference(Object sender) => _references.remove(sender.hashCode);

  @override
  void requestDispose([sender]) {
    if (sender != null) {
      removeReference(sender);
    }

    super.requestDispose(sender);
  }

  /// Clears all references.
  /// So [preferSoftDispose] is not set.
  void clearReferences() => _references.clear();

  @override
  void dispose() {
    super.dispose();

    _references.clear();
  }
}

mixin DisposeObserver on ControlModel {
  final _toDispose = <Disposable>[];

  void registerDispose(Disposable item) => _toDispose.add(item);

  void unregisterDispose(Disposable item) => _toDispose.remove(item);

  bool isRegisteredForDispose(Disposable item) => _toDispose.contains(item);

  @override
  void dispose() {
    super.dispose();

    for (final element in _toDispose) {
      element.dispose();
    }

    _toDispose.clear();
  }
}

/// Abstract disposable client with other callbacks.
class _DisposableClient implements Disposable {
  /// Parent of this disposer.
  final dynamic parent;

  /// Callback when token is finished and [finish] called.
  VoidCallback? onFinish;

  /// Callback when token is canceled and [finish] called.
  VoidCallback? onCancel;

  /// Callback when token is disposed and [finish] called.
  VoidCallback? onDispose;

  /// [parent] - Parent object of this client.
  _DisposableClient({this.parent});

  /// Finishes this token and notifies [onFinish] listener.
  void finish() => onFinish?.call();

  /// Cancels this token and notifies [onCancel] listener.
  void cancel() => onCancel?.call();

  @override
  void dispose() {
    onDispose?.call();
  }
}

/// [DisposableClient] is used at `Client` side and [DisposableToken] at `Model` side.
class DisposableClient extends _DisposableClient {
  /// [parent] - Parent object of this client.
  DisposableClient({super.parent});

  /// Creates [DisposableToken] that can be used by `Client`.
  DisposableToken asToken({dynamic data}) =>
      DisposableToken._(this, data: data);
}

/// [DisposableClient] is used at `Client` side and [DisposableToken] at `Model` side.
class DisposableToken extends _DisposableClient {
  /// Parent of this token.
  final _DisposableClient _client;

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

  /// [_client] - Parent client of this token.
  /// [data] - Initial token data.
  DisposableToken._(
    this._client, {
    this.data,
  });

  /// [parent] - Parent object of this token.
  /// [data] - Initial token data.
  /// [onCancel] - Client event that is called when token is canceled.
  /// [onFinish] - Client event that is called when token is finished.
  /// [onDispose] - Client event that is called when token is disposed.
  factory DisposableToken.client({
    dynamic parent,
    VoidCallback? onCancel,
    VoidCallback? onFinish,
    VoidCallback? onDispose,
    dynamic data,
  }) =>
      DisposableToken._(
        _DisposableClient(
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
