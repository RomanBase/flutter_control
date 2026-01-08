part of '../../core.dart';

/// An interface for objects that can be notified to propagate changes.
///
/// Implementing this class allows an object to be a target of a notification,
/// typically triggering it to update its listeners or state.
abstract class ObservableNotifier {
  /// Notify this object to propagate changes.
  void notify();
}

/// The fundamental interface for an observable object.
///
/// It defines the core ability to be listened to for changes and to be disposed of
/// when no longer needed.
///
/// - [T]: The type of value this observable deals with. For channels without a value, this is `void`.
abstract class ObservableBase<T> implements Disposable {
  /// Optional data that can be attached to the observable, often for internal
  /// use by components or for tracking purposes.
  dynamic internalData;

  /// Subscribes to the observable to be notified of changes.
  ///
  /// The provided [action] callback will be executed whenever the observable fires.
  ///
  /// Returns a [ControlSubscription] which can be used to cancel the subscription.
  ControlSubscription<T> listen(VoidCallback action);

  /// Cancels a subscription, preventing it from receiving further notifications.
  void cancel(ControlSubscription<T> subscription);
}

extension ObservableBaseExt on ObservableBase {
  /// Creates new group, that listens to both observables.
  ObservableGroup merge(Object other) => ObservableGroup([this, other]);
}

extension ObservableValuExt on ObservableValue {
  /// Cast this observable.
  ObservableValue<U> cast<U>() => this as ObservableValue<U>;
}

/// An observable that acts as a simple notification channel, without carrying a value.
///
/// It's useful for signaling events where no data payload is necessary.
/// Listeners are simply notified that an event has occurred.
abstract class ObservableChannel implements ObservableBase<void> {
  @override
  dynamic internalData;

  @override
  ControlSubscription<void> listen(VoidCallback action) => subscribe(action);

  /// Subscribes to the channel. The [action] is a `VoidCallback` since no value is passed.
  ///
  /// - [action]: The callback to execute when the channel notifies.
  /// - [current]: This parameter is typically ignored for channels as there is no value to deliver.
  /// - [args]: Optional arguments for the subscription.
  ControlSubscription subscribe(VoidCallback action,
      {bool current = true, args});
}

/// An observable that holds and notifies about changes to a single [value].
///
/// This is the most common type of observable, used for representing reactive state.
abstract class ObservableValue<T> implements ObservableBase<T> {
  /// The current value held by the observable.
  T get value;

  @override
  dynamic internalData;

  @override
  ControlSubscription<T> listen(VoidCallback action) =>
      subscribe((_) => action());

  /// Subscribes to changes in the observable's [value].
  ///
  /// - [action]: The callback to execute, which receives the new value.
  /// - [current]: If `true`, the [action] is immediately called with the current [value].
  /// - [args]: Optional arguments for the subscription.
  ControlSubscription<T> subscribe(ValueCallback<T> action,
      {bool current = true, args});
}

/// An abstract base class for creating a custom [ObservableValue].
///
/// It provides a standard structure for managing a value and notifying listeners,
/// including helper properties and a robust `setValue` method.
abstract class ObservableModel<T> extends ObservableValue<T>
    implements ObservableNotifier {
  /// Checks if [value] is not set.
  bool get isEmpty => value == null;

  /// Checks if [value] is set.
  bool get isNotEmpty => value != null;

  /// Checks validity of this observable.
  /// Invalid observers should not be notified.
  bool get isValid;

  /// Checks availability of this observable.
  /// Inactive observers should not be notified.
  bool get isActive;

  /// Standard [value] setter.
  /// If value is different then [notify] is called.
  set value(T value) => setValue(value);

  /// Sets the observable's value.
  ///
  /// - [value]: The new value to set.
  /// - [notify]: If `true` (default), listeners will be notified of the change. Set to `false`
  ///   to update the value silently.
  /// - [forceNotify]: If `true`, listeners will be notified even if the new value is the same
  ///   as the old one.
  void setValue(T value, {bool notify = true, bool forceNotify = false});
}

/// Just wrapper.
class _ObservableHandler<T> extends ObservableValue<T> {
  final ObservableValue<T> _parent;

  @override
  T get value => _parent.value;

  _ObservableHandler(this._parent);

  @override
  ControlSubscription<T> subscribe(ValueCallback<T> action,
          {bool current = true, dynamic args}) =>
      _parent.subscribe(
        action,
        current: current,
        args: args,
      );

  @override
  void cancel(ControlSubscription<T> subscription) =>
      _parent.cancel(subscription);

  @override
  void dispose() {
    _parent.dispose();
  }
}

/// The primary concrete implementation of an observable value.
///
/// This class manages a value, a list of subscribers, and handles the logic for
/// notifying subscribers when the value changes. It also provides factory constructors
/// to easily create observables from other reactive sources like `Stream`s and `Future`s.
class ControlObservable<T> extends ObservableModel<T> {
  /// Active subscriptions of this observable.
  /// This is exposed just for debug and test purposes.
  /// DO NOT modify this list externally!
  @protected
  final subs = <ControlSubscription<T>>[];

  final _toDispose = <Disposable>[];

  /// Checks if observable can serve changes to [subs].
  /// Activity can be [pause] and [resume].
  bool _active = true;

  /// Actual value.
  T _value;

  @override
  T get value => _value;

  @override
  bool get isValid => true;

  @override
  bool get isActive => isValid && _active;

  /// Number of active listeners.
  int get subCount => subs.length;

  /// Observable that handles listeners and [value] changes.
  /// Initial [value] of this object.
  /// This object must call [dispose] to release resources.
  ControlObservable(this._value);

  /// Creates an observable that can hold a nullable value.
  static ControlObservable<T?> empty<T>([T? value]) =>
      ControlObservable<T?>(value);

  /// Wraps an existing observable to hide its concrete implementation, exposing only the `ObservableValue` interface.
  static ObservableValue<T?> handle<T>(ObservableModel<T?> observable) =>
      _ObservableHandler<T?>(observable);

  /// A powerful factory that creates an [ObservableValue] from various sources.
  ///
  /// This method can adapt the following types into a unified observable interface:
  ///  - [ObservableValue]: Returns the object itself.
  ///  - [Stream]: Creates an observable that updates its value with each stream event.
  ///  - [Future]: Creates an observable that sets its value upon future completion.
  ///  - [Listenable] / [ValueListenable]: Creates an observable that listens for notifications.
  ///  - [ObservableChannel]: Creates an observable that notifies when the channel fires.
  ///
  /// If an unsupported object is provided, it will be wrapped in an observable as the initial value.
  static ObservableValue<T?> of<T>(Object? object) {
    if (T == dynamic) {
      if (object is ObservableValue) {
        return object.cast();
      } else if (object is Stream) {
        return ofStream(object).cast();
      } else if (object is Future) {
        return ofFuture(object).cast();
      } else if (object is Listenable) {
        return ofListenable(object).cast();
      } else if (object is ObservableBase) {
        return ofChannel(object).cast();
      }
    } else {
      if (object is ObservableValue<T>) {
        return object;
      } else if (object is Stream<T>) {
        return ofStream(object);
      } else if (object is Future<T>) {
        return ofFuture(object);
      } else if (object is Listenable) {
        return ofListenable(object);
      } else if (object is ObservableBase) {
        return ofChannel(object);
      }
    }

    return ControlObservable<T?>(object is T ? object : null);
  }

  /// Creates an observable from given [stream]. Stream value is propagated to this observable.
  /// This object listen to stream and notifies about [value] changes.
  static ControlObservable<T?> ofStream<T>(Stream<T> stream) {
    final observable = _ClientObservable<T>();
    final sub = stream.listen((event) => observable.setValue(event));

    observable.register(DisposableClient()..onDispose = () => sub.cancel());

    return observable;
  }

  /// Creates an observable from given [future]. Future value is propagated to this observable.
  /// This object waits to future completion and then sets [value].
  /// If error occurs nothing happens.
  static ControlObservable<T?> ofFuture<T>(Future<T> future) {
    final observable = ControlObservable<T?>(null);

    future.then((value) => observable.setValue(value)).catchError((err) {
      printDebug(err);
    });

    return observable;
  }

  /// Creates an observable from given [listenable]. Listenable value, if any, is propagated to this observable.
  /// This object listen to listenable and notifies about [value] changes (if [ValueListenable] is given).
  static ControlObservable<T?> ofListenable<T>(Listenable listenable) {
    final observable = _ClientObservable<T>();

    callback() {
      if (listenable is ValueListenable<T>) {
        observable.setValue(listenable.value, forceNotify: true);
      } else {
        observable.notify();
      }
    }

    listenable.addListener(callback);
    observable.register(DisposableClient()
      ..onDispose = () => listenable.removeListener(callback));

    return observable;
  }

  /// Creates an observable from given [channel].
  /// This object wraps channel and propagates their notifies.
  static ControlObservable<T?> ofChannel<T>(ObservableBase channel) {
    final observable = _ClientObservable<T>();

    channel.listen(() => observable.notify());

    return observable;
  }

  @override
  void setValue(T value, {bool notify = true, bool forceNotify = false}) {
    if (_value == value) {
      if (forceNotify) {
        this.notify();
      }

      return;
    }

    _value = value;

    if (notify || forceNotify) {
      this.notify();
    }
  }

  @override
  ControlSubscription<T> subscribe(ValueCallback<T> action,
      {bool current = true, dynamic args}) {
    final sub = createSubscription();
    subs.add(sub);

    sub.initSubscription(this, action);

    if (current) {
      sub.notifyCallback(value);
    }

    return sub;
  }

  @protected
  ControlSubscription<T> createSubscription([dynamic args]) =>
      ControlSubscription<T>();

  ControlSubscription<U> wrap<U>(ObservableValue<U> other,
      {T Function(U value)? converter, bool autoDispose = true}) {
    final sub = other.subscribe((value) {
      if (converter != null) {
        setValue(converter(value));
      } else {
        setValue(value as T);
      }
    });

    _toDispose.add(sub);

    if (autoDispose) {
      _toDispose.add(other);
    }

    return sub;
  }

  @override
  void cancel(ControlSubscription<T> subscription) {
    subscription.invalidate();
    subs.remove(subscription);
  }

  /// When observable is paused, then [notify] breaks all callbacks.
  void pause() => _active = false;

  /// Resume [notify] to listeners.
  /// Only [isValid] observable can be resumed.
  bool resume() => _active = isValid;

  @override
  void notify() {
    if (!isActive) {
      return;
    }

    // Notify all subs and remove invalid subs
    // TODO: performance?
    subs.removeWhere((element) {
      element.notifyCallback(value);
      return !element.isValid;
    });
  }

  /// Invalidates and clears all [subs].
  void clear() {
    for (final element in subs) {
      element.invalidate();
    }

    subs.clear();

    for (final value in _toDispose) {
      value.dispose();
    }
  }

  @override
  void dispose() {
    clear();
  }
}

/// Just wrapper to close input channel if needed.
class _ClientObservable<T> extends ControlObservable<T?> {
  Disposable? _disposable;

  _ClientObservable() : super(null);

  void register(Disposable object) {
    _disposable = object;
  }

  @override
  void dispose() {
    _disposable?.dispose();
    _disposable = null;

    super.dispose();
  }
}
