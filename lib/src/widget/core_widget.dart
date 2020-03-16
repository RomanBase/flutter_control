import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_control/core.dart';

class ControlArgHolder implements Disposable {
  bool _valid = true;
  ControlArgs _cache;
  ArgState _state;

  ArgState get state => _state;

  bool get isValid => _valid;

  bool get isCacheActive => _cache != null;

  bool get initialized => _state != null;

  Map get args => argStore?.data;

  ControlArgs get argStore => _state?.args ?? _cache ?? (_cache = ControlArgs());

  void init(ArgState state) {
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

  @override
  void dispose() {
    _cache = argStore;
    _valid = false;
    _state = null;
  }
}

abstract class CoreWidget extends StatefulWidget implements Initializable, Disposable {
  final holder = ControlArgHolder();

  BuildContext get context => holder?.state?.context;

  CoreWidget({Key key}) : super(key: key);

  @override
  void init(Map args) {}

  @protected
  void onStateInitialized() {}

  /// Adds [arg] to this widget.
  /// [args] can be whatever - [Map], [List], [Object], or any primitive.
  /// [args] are then parsed into [Map].
  void addArg(dynamic args) => holder.set(args);

  /// Returns value by given key or type.
  /// Args are passed to Widget in constructor and during [init] phase or can be added via [ControlWidget.addArg].
  T getArg<T>({dynamic key, T defaultValue}) => holder.get<T>(key: key, defaultValue: defaultValue);

  void removeArg<T>({dynamic key}) => holder.argStore.remove<T>(key: key);

  @override
  void dispose() {}
}

abstract class ArgState<T extends CoreWidget> extends State<T> {
  ControlArgs _args;

  ControlArgs get args => _args ?? (_args = ControlArgs());

  @override
  void dispose() {
    super.dispose();

    widget.holder.dispose();
  }
}

/// Copy of [SingleTickerProviderStateMixin] for [CoreWidget].
mixin SingleTickerControl on CoreWidget implements TickerProvider {
  @protected
  TickerProvider get ticker => this;

  Ticker get _ticker => getArg<Ticker>();

  @override
  Ticker createTicker(TickerCallback onTick) {
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

    addArg(Ticker(onTick, debugLabel: kDebugMode ? 'created by $this' : null));
    // We assume that this is called from initState, build, or some sort of
    // event handler, and that thus TickerMode.of(context) would return true. We
    // can't actually check that here because if we're in initState then we're
    // not allowed to do inheritance checks yet.
    return _ticker;
  }

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

    removeArg<Ticker>();

    super.dispose();
  }

  @override
  void onStateInitialized() {
    if (_ticker != null) _ticker.muted = !TickerMode.of(context);

    super.onStateInitialized();
  }
}

/// Copy of [TickerProviderStateMixin] for [CoreWidget].
mixin TickerControl on CoreWidget implements TickerProvider {
  @protected
  TickerProvider get ticker => this;

  Set<Ticker> get _tickers => getArg(key: Ticker);

  @override
  Ticker createTicker(TickerCallback onTick) {
    if (_tickers == null) {
      holder.argStore.add(key: Ticker, value: Set<_WidgetTicker>());
    }

    final _WidgetTicker result = _WidgetTicker(onTick, this, debugLabel: 'created by $this');
    _tickers.add(result);
    return result;
  }

  void _removeTicker(_WidgetTicker ticker) {
    assert(_tickers != null);
    assert(_tickers.contains(ticker));
    _tickers.remove(ticker);
  }

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

    removeArg<Set<_WidgetTicker>>();

    super.dispose();
  }

  @override
  void onStateInitialized() {
    final bool muted = !TickerMode.of(context);
    if (_tickers != null) {
      for (Ticker ticker in _tickers) {
        ticker.muted = muted;
      }
    }

    super.onStateInitialized();
  }
}

class _WidgetTicker extends Ticker {
  _WidgetTicker(TickerCallback onTick, this._creator, {String debugLabel}) : super(onTick, debugLabel: debugLabel);

  final TickerControl _creator;

  @override
  void dispose() {
    _creator._removeTicker(this);
    super.dispose();
  }
}
