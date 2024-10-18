part of '../../core.dart';

/// Class that can be notified about any changes.
abstract class ObservableNotifier {
  /// Notify this object to propagate changes.
  void notify();
}

/// Simple observable channel that notifies others about changes.
/// These changes are typically not part of this class.
/// Channel serves more like robust callback system.
abstract class ObservableChannel implements Disposable {
  /// Subscribe to listen future changes.
  ControlSubscription subscribe(
    VoidCallback action, {
    dynamic args,
  });

  /// Cancel given [subscription].
  void cancel(ControlSubscription subscription);

  /// Creates new group, that listens to both observables.
  ObservableGroup merge(Object other) => ObservableGroup([this, other]);

  @override
  void dispose() {}
}

/// Simple observable that notifies others about [value] changes.
/// Actual value is stored within this class.
abstract class ObservableValue<T> implements Disposable {
  /// Current value of this observable.
  T get value;

  /// Serves for internal data or markers.
  /// Exposed to public API due to usage as custom 'client' data.
  dynamic internalData;

  /// Cast this observable.
  ObservableValue<U> cast<U>() => this as ObservableValue<U>;

  /// Subscribe to listen future changes.
  ControlSubscription<T> subscribe(
    ValueCallback<T?> action, {
    bool current = true,
    dynamic args,
  });

  /// Cancel given [subscription].
  void cancel(ControlSubscription<T> subscription);

  /// Creates new group, that listens to both observables.
  ObservableGroup merge(Object other) => ObservableGroup([this, other]);

  @override
  void dispose() {}
}

///
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

  /// Robust [value] setter.
  /// [notify] when set is called when [value] is different.
  /// Disable [notify] to prevent propagation of this value change. This can be handy when we change [value] multiple times during one function call and we want to notify just last change.
  /// Enable [forceNotify] to notify listeners even if [value] is not changed.
  void setValue(T value, {bool notify = true, bool forceNotify = false});

  /// Returns new instance of [ObservableModel].
  /// Whenever [notify] is called then [FutureBlock.delayed] is triggered.
  /// So listeners are notified after [duration] finishes.
  ObservableModel<T> delayed(Duration duration) =>
      DelayedObservable(this, duration);
}

/// Just wrapper.
class _ObservableHandler<T> extends ObservableValue<T> {
  final ObservableValue<T> _parent;

  @override
  T get value => _parent.value;

  _ObservableHandler(this._parent);

  @override
  ControlSubscription<T> subscribe(ValueCallback<T?> action,
          {bool current = true, dynamic args}) =>
      _parent.subscribe(
        action,
        current: current,
        args: args,
      );

  @override
  void cancel(ControlSubscription<T> subscription) =>
      _parent.cancel(subscription);
}

/// Observable class that handles listeners and [value] changes.
class ControlObservable<T> extends ObservableModel<T> {
  /// Active subscriptions of this observable.
  /// This is exposed just for debug and test purposes.
  /// DO NOT modify this list externally!
  @protected
  final subs = <ControlSubscription<T>>[];

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

  /// Returns null version of observable.
  static ControlObservable<T?> empty<T>([T? value]) =>
      ControlObservable<T?>(value);

  /// Wraps given [observable]. Can be handy to 'hide' concrete functionality.
  static ObservableValue<T?> handle<T>(ObservableModel<T?> observable) =>
      _ObservableHandler<T?>(observable);

  /// Creates an observable from given [object].
  /// This method is able to consume:
  ///  - [ObservableValue] - [ControlObservable], [ActionControl], [FieldControl], [ObservableComponent]
  ///  - [ObservableChannel] - [NotifierComponent]
  ///  - [Stream]
  ///  - [Future]
  ///  - [Listenable], [ValueListenable] - [ChangeNotifier], [ValueNotifier]
  ///  - if unsupported type is given, then ObservableValue is created with given object, if T is met.
  ///  If given [object] serves any kind of result, then [value] is set.
  ///  Check [ofChannel], [ofStream], [ofFuture], [ofListenable] constructors.
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
      } else if (object is ObservableChannel) {
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
      } else if (object is ObservableChannel) {
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
  static ControlObservable<T?> ofChannel<T>(ObservableChannel channel) {
    final observable = _ClientObservable<T>();

    channel.subscribe(() => observable.notify());

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

///Just PoC - but we need generic solution around [ObservableNotifier] and/or [ControlSubscription] and expose all concrete functions of [parent].
///Current workaround is to use Rx Stream with [FieldControl.of].
///With macros, we will be able to do whatever :)
@deprecated
class DelayedObservable<T> extends ObservableModel<T> {
  final _block = FutureBlock();
  final ObservableModel<T> parent;

  Duration duration;

  @override
  T get value => parent.value;

  @override
  bool get isActive => parent.isActive;

  @override
  bool get isValid => parent.isValid;

  DelayedObservable(this.parent, this.duration);

  @override
  void setValue(T value, {bool notify = true, bool forceNotify = false}) =>
      parent.setValue(
        value,
        notify: notify,
        forceNotify: forceNotify,
      );

  @override
  ControlSubscription<T> subscribe(ValueCallback<T?> action,
          {bool current = true, args}) =>
      parent.subscribe(
        action,
        current: current,
        args: args,
      );

  @override
  void cancel(ControlSubscription<T> subscription) =>
      parent.cancel(subscription);

  @override
  void notify() => _block.delayed(duration, () => parent.notify());

  @override
  void dispose() {
    super.dispose();

    parent.dispose();
  }
}
