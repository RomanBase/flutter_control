part of '../../core.dart';

/// Dump marker used to mark object for dispose.
typedef DisposeMarker = Function();

/// A mixin that marks an object as having resources that need to be cleaned up.
///
/// Implementing `Disposable` signals that an object has a [dispose] method
/// which should be called to release resources like stream subscriptions or
/// close connections, preparing the object for garbage collection.
mixin Disposable {
  /// Releases resources used by the object.
  ///
  /// This method should be idempotent, meaning it can be called multiple times
  /// without causing errors.
  void dispose();
}

extension DisposableExt on Disposable {
  /// Register for dispose with given [observer].
  void disposeWith(DisposeObserver observer) => observer.registerDispose(this);
}

/// A mixin that provides sophisticated control over an object's disposal logic.
///
/// It introduces the concept of "soft dispose" vs. a full "dispose", controlled
/// by the [requestDispose] method.
///
/// - [preventDispose]: If `true`, all calls to `requestDispose` are ignored.
/// - [preferSoftDispose]: If `true`, `requestDispose` will call [softDispose] instead of the full [dispose].
mixin DisposeHandler implements Disposable {
  /// [requestDispose] do nothing if set. Final [dispose] must be handled manually.
  bool preventDispose = false;

  /// [requestDispose] will execute [softDispose]. Useful for items in list and objects stored in [ControlFactory]. Final [dispose] must be handled manually.
  bool preferSoftDispose = false;

  /// Executes a disposal action based on the handler's configuration.
  ///
  /// This is the primary way to trigger disposal for an object with this mixin.
  ///
  /// - [sender]: The object requesting the disposal.
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

  /// A method for partial disposal, like canceling subscriptions, without fully
  /// invalidating the object.
  ///
  /// This is useful for objects that are temporarily inactive but may be reused,
  /// such as items in a recycled list view.
  void softDispose() {}

  @override
  void dispose() {
    softDispose();
  }

  /// A utility to safely request disposal of an object, regardless of whether
  /// it uses `DisposeHandler` or just `Disposable`.
  static void disposeOf(Object? object, Object? sender) {
    if (object is DisposeHandler) {
      object.requestDispose(sender);
    } else if (object is Disposable) {
      object.dispose();
    }
  }
}

/// A mixin that adds reference counting to a [DisposeHandler].
///
/// It prevents an object from being fully disposed as long as it has active references.
/// When the reference count is greater than zero, `preferSoftDispose` is automatically
/// set to `true`.
///
/// This is very useful for models shared across multiple widgets. Each widget adds a
/// reference when it starts using the model and removes it when it's done. The model
/// will only be fully disposed of when the last reference is removed.
mixin ReferenceCounter on DisposeHandler {
  /// List of references.
  final _references = <int>[];

  /// Number of registered references.
  int get referenceCount => _references.length;

  @override
  bool get preferSoftDispose => _references.isNotEmpty;

  /// Adds a reference to this object.
  ///
  /// The [sender]'s `hashCode` is stored to track the reference.
  void addReference(Object sender) {
    if (_references.contains(sender.hashCode)) {
      return;
    }

    _references.add(sender.hashCode);
  }

  /// Removes a reference from this object.
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

/// A mixin for a [ControlModel] that allows it to manage the lifecycle of other [Disposable] objects.
///
/// When the model with this mixin is disposed, it will automatically call `dispose()` on all
/// registered objects.
mixin DisposeObserver on ControlModel {
  final _toDispose = <Disposable>[];

  /// Registers a [Disposable] item to be disposed when this observer is disposed.
  void registerDispose(Disposable item) => _toDispose.add(item);

  /// Unregisters a [Disposable] item.
  void unregisterDispose(Disposable item) => _toDispose.remove(item);

  /// Checks if a [Disposable] item is currently registered.
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

/// Manages a disposable resource and its callbacks between a provider and a client.
///
/// This is part of the [DisposableToken] pattern.
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

/// The client-side part of a disposable resource management pattern.
///
/// It creates a [DisposableToken] which is given to the party that uses the resource.
class DisposableClient extends _DisposableClient {
  /// [parent] - Parent object of this client.
  DisposableClient({super.parent});

  /// Creates a [DisposableToken] that can be used by the resource consumer.
  DisposableToken asToken({dynamic data}) =>
      DisposableToken._(this, data: data);
}

/// The token part of a disposable resource management pattern, used by the resource consumer.
///
/// A `DisposableToken` represents a single-use resource or operation. The consumer
/// can `cancel` it, and the provider can `finish` or `dispose` it. This provides a
/// clear and safe way to manage the lifecycle of asynchronous operations or temporary resources.
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

  /// Creates a standalone token without a separate `DisposableClient`.
  ///
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
