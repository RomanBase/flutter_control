part of '../../core.dart';

class ControlSubscription<T> implements Disposable {
  ObservableValue? _parent;
  ValueCallback<T>? _callback;

  Predicate<T>? _until;

  Predicate<T>? _filter;

  bool _active = true;

  bool get isValid => _parent != null;

  bool get isActive => isValid && _active;

  bool get isCallbackAttached => _callback != null;

  void initSubscription(ObservableValue parent, [ValueCallback<T>? callback]) {
    _parent = parent;
    _callback = callback;
  }

  ControlSubscription<T> filter(Predicate<T>? filter) {
    _filter = filter;
    return this;
  }

  ControlSubscription<T> until(Predicate<T>? predicate) {
    _until = predicate;
    return this;
  }

  ControlSubscription<T> once() {
    _until = (value) => true;
    return this;
  }

  bool closePass(T value) => _until?.call(value) ?? false;

  bool filterPass(T value) => _filter?.call(value) ?? true;

  void pause() => _active = false;

  void resume() => _active = isValid;

  void notifyCallback(T value) {
    if (!isActive || !filterPass(value)) {
      return;
    }

    _callback?.call(value);

    if (closePass(value)) {
      invalidate();
    }
  }

  void cancel() {
    _active = false;
    _parent?.cancel(this);

    invalidate();
  }

  void invalidate() {
    _active = false;
    _parent = null;
    _callback = null;
  }

  @override
  void dispose() {
    if (isValid) {
      cancel();
    }
  }
}
