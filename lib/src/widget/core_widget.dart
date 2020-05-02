import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_control/core.dart';

class ControlArgHolder implements Disposable {
  bool _valid = true;
  ControlArgs _cache;
  CoreState _state;

  CoreState get state => _state;

  bool get isValid => _valid;

  bool get isCacheActive => _cache != null;

  bool get initialized => _state != null;

  Map get args => argStore?.data;

  ControlArgs get argStore => _state?.args ?? _cache ?? (_cache = ControlArgs());

  void init(CoreState state) {
    _state = state;
    _valid = true;

    if (_cache != null) {
      argStore.set(_cache);
      _cache = null;
    }
  }

  void set(dynamic args) => argStore.set(args);

  T get<T>({dynamic key, T defaultValue}) => Parse.getArg<T>(args, key: key, defaultValue: defaultValue);

  List<ControlModel> findControls() => argStore.getAll<ControlModel>() ?? [];

  void copy(ControlArgHolder oldHolder) {
    if (oldHolder.initialized) {
      init(oldHolder.state);
    }

    argStore.set(oldHolder.argStore);
  }

  @override
  void dispose() {
    _cache = argStore;
    _valid = false;
    _state = null;
  }
}

abstract class CoreWidget extends StatefulWidget implements Initializable, Disposable {
  final holder = ControlArgHolder();

  ControlArgs get store => holder.argStore; //TODO

  BuildContext get context => holder?.state?.context;

  CoreWidget({Key key, dynamic args}) : super(key: key) {
    holder.set(args);
  }

  /// When [RouteHandler] is used, then this function is called right after Widget construction. +
  /// All controllers (from [initControls]) are initialized too.
  @override
  @protected
  @mustCallSuper
  void init(Map args) => addArg(args);

  /// [State.didChangeDependencies]
  @protected
  void onInit(Map args) {
    if (this is ThemeProvider) {
      (this as ThemeProvider).invalidateTheme(context);
    }
  }

  @protected
  bool notifyUpdate(CoreWidget oldWidget) {
    holder.copy(oldWidget.holder);

    return !holder.initialized;
  }

  @protected
  void onUpdate(CoreWidget oldWidget, CoreState state) {
    _notifyHolder(state);
  }

  @protected
  void _notifyHolder(CoreState state) {
    assert(() {
      if (holder.initialized && holder.state != state) {
        printDebug('state re-init of: ${this.runtimeType.toString()}');
        printDebug('old state: ${holder.state}');
        printDebug('new state: $state');
      }
      return true;
    }());

    if (holder.state == state) {
      return;
    }

    holder.init(state);
  }

  /// Adds [arg] to this widget.
  /// [args] can be whatever - [Map], [List], [Object], or any primitive.
  /// [args] are then parsed into [Map].
  void addArg(dynamic args) => holder.set(args);

  void setArg({dynamic key, @required dynamic value}) => holder.argStore.add(key: key, value: value);

  /// Returns value by given key or type.
  /// Args are passed to Widget in constructor and during [init] phase or can be added via [ControlWidget.addArg].
  T getArg<T>({dynamic key, T defaultValue}) => holder.get<T>(key: key, defaultValue: defaultValue);

  void removeArg<T>({dynamic key}) => holder.argStore.remove<T>(key: key);

  @override
  void dispose() {}
}

abstract class CoreState<T extends CoreWidget> extends State<T> {
  ControlArgs _args;

  ControlArgs get args => _args ?? (_args = ControlArgs());

  @override
  @mustCallSuper
  void initState() {
    super.initState();

    widget._notifyHolder(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    widget.onInit(_args.data);
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.notifyUpdate(oldWidget)) {
      widget.onUpdate(oldWidget, this);
    }
  }

  @override
  void dispose() {
    super.dispose();

    widget.holder.dispose();
  }
}

class _SingleTickerComponent extends ControlModel implements TickerProvider {
  Ticker _ticker;

  @override
  Ticker createTicker(onTick) {
    assert(() {
      if (_ticker == null) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('$runtimeType is a SingleTickerProviderStateMixin but multiple tickers were created.'),
        ErrorDescription('A SingleTickerProviderStateMixin can only be used as a TickerProvider once.'),
        ErrorHint('If a State is used for multiple AnimationController objects, or if it is passed to other '
            'objects and those objects might use it more than one time in total, then instead of '
            'mixing in a SingleTickerProviderStateMixin, use a regular TickerProviderStateMixin.')
      ]);
    }());
    _ticker = Ticker(onTick, debugLabel: kDebugMode ? 'created by $this' : null);
    // We assume that this is called from initState, build, or some sort of
    // event handler, and that thus TickerMode.of(context) would return true. We
    // can't actually check that here because if we're in initState then we're
    // not allowed to do inheritance checks yet.
    return _ticker;
  }

  void _muteTicker(bool muted) => _ticker?.muted = muted;

  @override
  void dispose() {
    assert(() {
      if (_ticker == null || !_ticker.isActive) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('$this was disposed with an active Ticker.'),
        ErrorDescription('$runtimeType created a Ticker via its SingleTickerProviderStateMixin, but at the time '
            'dispose() was called on the mixin, that Ticker was still active. The Ticker must '
            'be disposed before calling super.dispose().'),
        ErrorHint('Tickers used by AnimationControllers '
            'should be disposed by calling dispose() on the AnimationController itself. '
            'Otherwise, the ticker will leak.'),
        _ticker.describeForError('The offending ticker was')
      ]);
    }());

    _ticker?.dispose();
    _ticker = null;

    super.dispose();
  }
}

///Check [SingleTickerProviderStateMixin]
mixin SingleTickerControl on CoreWidget implements TickerProvider {
  final _ticker = _SingleTickerComponent();

  TickerProvider get ticker => this;

  @override
  Ticker createTicker(onTick) => _ticker.createTicker(onTick);

  @override
  void onInit(Map args) {
    _ticker._muteTicker(!TickerMode.of(context));

    super.onInit(args);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class _TickerComponent extends ControlModel implements TickerProvider {
  Set<Ticker> _tickers;

  @override
  Ticker createTicker(TickerCallback onTick) {
    _tickers ??= <_WidgetTicker>{};
    final _WidgetTicker result = _WidgetTicker(onTick, this, debugLabel: 'created by $this');
    _tickers.add(result);
    return result;
  }

  void _removeTicker(_WidgetTicker ticker) {
    assert(_tickers != null);
    assert(_tickers.contains(ticker));
    _tickers.remove(ticker);
  }

  void _muteTicker(bool muted) => _tickers?.forEach((item) => item.muted = muted);

  @override
  void dispose() {
    assert(() {
      if (_tickers != null) {
        for (Ticker ticker in _tickers) {
          if (ticker.isActive) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('$this was disposed with an active Ticker.'),
              ErrorDescription('$runtimeType created a Ticker via its TickerProviderStateMixin, but at the time '
                  'dispose() was called on the mixin, that Ticker was still active. All Tickers must '
                  'be disposed before calling super.dispose().'),
              ErrorHint('Tickers used by AnimationControllers '
                  'should be disposed by calling dispose() on the AnimationController itself. '
                  'Otherwise, the ticker will leak.'),
              ticker.describeForError('The offending ticker was'),
            ]);
          }
        }
      }
      return true;
    }());

    _tickers?.forEach((item) => item.dispose());
    _tickers = null;

    super.dispose();
  }
}

///Check [TickerProviderStateMixin]
mixin TickerControl on CoreWidget implements TickerProvider {
  final _ticker = _TickerComponent();

  TickerProvider get ticker => this;

  @override
  Ticker createTicker(TickerCallback onTick) => _ticker.createTicker(onTick);

  @override
  void onInit(Map args) {
    _ticker._muteTicker(!TickerMode.of(context));

    super.onInit(args);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class _WidgetTicker extends Ticker {
  _WidgetTicker(TickerCallback onTick, this._creator, {String debugLabel}) : super(onTick, debugLabel: debugLabel);

  final _TickerComponent _creator;

  @override
  void dispose() {
    _creator._removeTicker(this);
    super.dispose();
  }
}

mixin OnLayout on CoreWidget {
  @override
  void onInit(Map args) {
    super.onInit(args);

    WidgetsBinding.instance.addPostFrameCallback((_) => onLayout());
  }

  void onLayout();
}
