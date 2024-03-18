part of flutter_control;

/// Mostly copy of [SingleTickerProviderStateMixin].
class _SingleTickerProvider implements Disposable, TickerProvider {
  Ticker? _ticker;

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
    return _ticker!;
  }

  void _muteTicker(bool muted) => _ticker?.muted = muted;

  @override
  void dispose() {
    assert(() {
      if (_ticker == null || !_ticker!.isActive) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('$this was disposed with an active Ticker.'),
        ErrorDescription('$runtimeType created a Ticker via its SingleTickerProviderStateMixin, but at the time '
            'dispose() was called on the mixin, that Ticker was still active. The Ticker must '
            'be disposed before calling super.dispose().'),
        ErrorHint('Tickers used by AnimationControllers '
            'should be disposed by calling dispose() on the AnimationController itself. '
            'Otherwise, the ticker will leak.'),
        _ticker!.describeForError('The offending ticker was')
      ]);
    }());

    _ticker?.dispose();
    _ticker = null;
  }
}

/// Check [SingleTickerProviderStateMixin]
mixin SingleTickerControl on CoreWidget implements TickerProvider {
  final _ticker = _SingleTickerProvider();

  TickerProvider get ticker => this;

  @override
  Ticker createTicker(onTick) => _ticker.createTicker(onTick);

  @override
  void onInit(Map args, CoreContext context) {
    _ticker._muteTicker(!TickerMode.of(context));

    super.onInit(args, context);
  }

  @override
  void onDispose() {
    _ticker.dispose();
    super.onDispose();
  }
}

/// Mostly copy of [TickerProviderStateMixin].
class _TickerProvider implements Disposable, TickerProvider {
  Set<Ticker>? _tickers;

  @override
  Ticker createTicker(TickerCallback onTick) {
    _tickers ??= <_WidgetTicker>{};

    final ticker = _WidgetTicker(onTick, this, debugLabel: 'created by $this');
    _tickers!.add(ticker);

    return ticker;
  }

  void _removeTicker(_WidgetTicker ticker) {
    if (_tickers == null) {
      return;
    }

    _tickers!.remove(ticker);
  }

  void _muteTicker(bool muted) => _tickers?.forEach((item) => item.muted = muted);

  @override
  void dispose() {
    assert(() {
      if (_tickers != null) {
        for (Ticker ticker in _tickers!) {
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

    _tickers?.clear();
    _tickers = null;
  }
}

/// Check [TickerProviderStateMixin]
mixin TickerControl on CoreWidget implements TickerProvider {
  final _ticker = _TickerProvider();

  TickerProvider get ticker => this;

  @override
  Ticker createTicker(TickerCallback onTick) => _ticker.createTicker(onTick);

  @override
  void onInit(Map args, CoreContext context) {
    _ticker._muteTicker(!TickerMode.of(context));

    super.onInit(args, context);
  }

  @override
  void onDispose() {
    super.onDispose();

    _ticker.dispose();
  }
}

class _WidgetTicker extends Ticker {
  _TickerProvider? _creator;

  bool get isMounted => _creator != null;

  _WidgetTicker(TickerCallback onTick, this._creator, {String? debugLabel}) : super(onTick, debugLabel: debugLabel);

  @override
  void dispose() {
    _creator?._removeTicker(this);
    _creator = null;

    super.dispose();
  }
}
