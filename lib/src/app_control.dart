import 'package:flutter_control/core.dart';

class AppControl extends InheritedWidget {
  /// Runtime Type of class.
  /// Used for custom class integration.
  static Type _accessType;

  /// returns nearest AppControl to given context.
  /// nullable
  static AppControl of(BuildContext context) {
    if (context != null) {
      final control = context.inheritFromWidgetOfExactType(_accessType);

      if (control != null) {
        return control;
      }
    }

    return ControlProvider.get(ControlKey.control);
  }

  /// Key of root State.
  final GlobalKey rootKey;

  /// Global key of [AppControl]
  GlobalKey get mainKey => key;

  /// Holder of current root context.
  /// Don't get/set context directly - use [rootContext] instead.
  final ContextHolder _contextHolder;

  /// Returns current context from [contextHolder]
  BuildContext get rootContext => _contextHolder.context;

  /// Sets new root context to [contextHolder]
  set rootContext(BuildContext context) => _contextHolder.changeContext(context);

  final StateNotifier _rootStateNotifier;

  final _context = ActionControl<BuildContext>.broadcast();

  /// [rootKey] is passed just like reference.
  /// Holds global [State] and root [BuildContext].
  /// Root context can be changed via [rootContext].
  AppControl._(
    this.rootKey,
    this._contextHolder,
    this._rootStateNotifier,
    Widget child,
  ) : super(key: GlobalObjectKey(child), child: child) {
    assert(rootKey != null);
    assert(_contextHolder != null);

    _accessType = this.runtimeType;

    _contextHolder.subscribe(_context.setValue);

    ControlFactory.of(this).set(key: ControlKey.control, value: this);
  }

  ControlSubscription<BuildContext> subscribeContextChanges(ValueCallback<BuildContext> callback) => _context.subscribe(callback);

  ControlSubscription<BuildContext> subscribeNextContextChange(ValueCallback<BuildContext> callback) => _context.once(callback);

  factory AppControl.init({
    GlobalKey rootKey,
    @required ContextHolder contextHolder,
    StateNotifier rootStateNotifier,
    Widget child,
  }) {
    rootKey ??= child?.key as GlobalKey;
    rootStateNotifier ??= rootKey?.currentState as StateNotifier;

    return AppControl._(
      rootKey,
      contextHolder,
      rootStateNotifier,
      child,
    );
  }

  void notifyAppState([dynamic state]) {
    if (_rootStateNotifier != null) {
      _rootStateNotifier.notifyState(state);
    } else if (rootKey?.currentState is StateNotifier) {
      (rootKey.currentState as StateNotifier).notifyState(state);
    } else if ((child?.key as GlobalKey)?.currentState is StateNotifier) {
      ((child.key as GlobalKey).currentState as StateNotifier).notifyState(state);
    } else {
      printDebug('No notifier found. Set "rootStateNotifier" or "rootKey.currentState" or "child.key.currentState" with StateNotifier');
    }
  }

  @override
  bool updateShouldNotify(AppControl oldWidget) {
    return false;
  }
}
